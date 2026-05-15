require 'sketchup.rb'
require 'json'

module ArchitechAIAssistant_v6
  @dialog = nil

  def self.open_assistant
    @dialog = UI::HtmlDialog.new({
      :dialog_title => "Architech AI - 智能分類引擎 v6.0",
      :width => 500, :height => 800,
      :style => UI::HtmlDialog::STYLE_DIALOG
    })

    html = <<-HTML
      <html>
        <head>
          <style>
            body { font-family: 'Segoe UI', sans-serif; padding: 15px; background: #f4f4f4; color: #333; }
            .card { background: white; padding: 15px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 20px; }
            textarea { width: 100%; height: 80px; font-family: monospace; font-size: 11px; margin: 10px 0; border: 1px solid #ccc; padding: 8px; box-sizing: border-box; background: #282c34; color: #abb2bf; }
            button { width: 100%; padding: 12px; border: none; border-radius: 4px; cursor: pointer; font-weight: bold; margin-bottom: 8px; transition: 0.2s; }
            .btn-magic { background: #8e44ad; color: white; }
            .btn-scan { background: #007bff; color: white; }
            .btn-apply { background: #d35400; color: white; margin-top: 5px; }
            h4 { margin: 0 0 5px 0; color: #444; border-bottom: 2px solid #eee; padding-bottom: 5px; font-size: 14px; }
            .badge { display: inline-block; background: #ffeaa7; color: #d35400; padding: 2px 6px; border-radius: 4px; font-size: 10px; margin-bottom: 10px;}
          </style>
        </head>
        <body>
          <div class="card">
            <h4>Step 1: 幾何智能體檢 (Auto-Tagger)</h4>
            <span class="badge">無須手動圖層！AI 自動辨識牆壁/地板</span>
            <button class="btn-magic" onclick="sketchup.auto_tag_geometry()">✨ 一鍵智慧幾何分類</button>
          </div>
          
          <div class="card">
            <h4>Step 2: 掃描分類結果 (Tag Scanner)</h4>
            <button class="btn-scan" onclick="sketchup.scan_selection()">🔍 掃描框選區塊的圖層</button>
            <textarea id="out_data" readonly placeholder="分類後的結果將顯示於此..."></textarea>
            <button class="btn-scan" style="background:#6c757d;" onclick="copyData()">複製清單</button>
          </div>

          <div class="card">
            <h4>Step 3: AI 極速分色 (Prep for Render)</h4>
            <textarea id="in_data" placeholder='貼上 AI 給的 Hex Code JSON...'></textarea>
            <button class="btn-apply" onclick="applyBatch()">🎨 執行圖層分色</button>
          </div>
          <script>
            window.updateUI = function(data) { document.getElementById('out_data').value = JSON.stringify(data, null, 2); };
            function copyData() { const el = document.getElementById("out_data"); el.select(); document.execCommand("copy"); alert("已複製！"); }
            function applyBatch() { 
              const val = document.getElementById('in_data').value;
              try { sketchup.process_batch(JSON.parse(val)); } catch(e) { alert("JSON 格式錯誤！"); }
            }
          </script>
        </body>
      </html>
    HTML

    @dialog.set_html(html)
    @dialog.add_action_callback("auto_tag_geometry") { |_, _| self.execute_auto_tagger }
    @dialog.add_action_callback("scan_selection") { |_, _| self.execute_tag_scan }
    @dialog.add_action_callback("process_batch") { |_, params| self.batch_apply_solid_colors(params) }
    @dialog.show
  end

  # --- [新增] 功能 0：幾何特徵啟發式自動分類 ---
  def self.execute_auto_tagger
    model = Sketchup.active_model
    sel = model.selection
    return UI.messagebox("請框選要進行體檢的模型！") if sel.empty?

    model.start_operation('AI Auto Tagging', true)

    # 確保 AI 專用圖層存在
    @layers = {
      wall: model.layers.add("AI_Auto_Wall"),
      floor: model.layers.add("AI_Auto_Floor"),
      ceiling: model.layers.add("AI_Auto_Ceiling"),
      other: model.layers.add("AI_Auto_Misc")
    }

    @stats = { wall: 0, floor: 0, ceiling: 0, skipped: 0 }
    
    self.recursive_auto_tag(sel)
    
    model.commit_operation
    UI.messagebox("✨ 體檢分類完成！\n辨識出:\n牆壁: #{@stats[:wall]} 面\n地板: #{@stats[:floor]} 面\n天花板/屋頂: #{@stats[:ceiling]} 面\n太小或複雜面已略過: #{@stats[:skipped]} 面")
  end

  def self.recursive_auto_tag(entities)
    entities.each do |ent|
      if ent.is_a?(Sketchup::Face)
        # 過濾太小的面 (SketchUp 預設單位為平方英吋，100 sq inch 約 0.06 平方公尺)
        if ent.area < 100
          @stats[:skipped] += 1
          next
        end

        nz = ent.normal.z
        if nz.abs < 0.15 # 牆面 (Z向量接近0)
          ent.layer = @layers[:wall]
          @stats[:wall] += 1
        elsif nz > 0.85 # 地板 (Z向量朝上)
          ent.layer = @layers[:floor]
          @stats[:floor] += 1
        elsif nz < -0.85 # 天花板/屋頂 (Z向量朝下)
          ent.layer = @layers[:ceiling]
          @stats[:ceiling] += 1
        else
          ent.layer = @layers[:other] # 斜屋頂或複雜幾何
        end
      elsif ent.is_a?(Sketchup::Group)
        self.recursive_auto_tag(ent.entities)
      elsif ent.is_a?(Sketchup::ComponentInstance)
        self.recursive_auto_tag(ent.definition.entities)
      end
    end
  end

  # --- 功能 1：具備繼承能力的圖層掃描 ---
  def self.execute_tag_scan
    sel = Sketchup.active_model.selection
    return UI.messagebox("請先用滑鼠框選模型！") if sel.empty?
    @tag_stats = {}; @total_faces = 0
    self.dig_and_scan_tags(sel, "Untagged")
    export_data = { "action": "analyze_scene_by_tags", "total_faces_found": @total_faces, "tags_in_scene": @tag_stats.map { |k, v| { "tag_name": k, "face_count": v } } }
    @dialog.execute_script("updateUI(#{export_data.to_json})")
  end

  def self.dig_and_scan_tags(entities, parent_layer_name)
    entities.each do |ent|
      effective_layer = (ent.layer.name == "Layer0" || ent.layer.name == "Untagged") ? parent_layer_name : ent.layer.name
      if ent.is_a?(Sketchup::Face)
        @total_faces += 1; @tag_stats[effective_layer] ||= 0; @tag_stats[effective_layer] += 1
      elsif ent.is_a?(Sketchup::Group)
        self.dig_and_scan_tags(ent.entities, effective_layer)
      elsif ent.is_a?(Sketchup::ComponentInstance)
        self.dig_and_scan_tags(ent.definition.entities, effective_layer)
      end
    end
  end

  # --- 功能 2：極速離線純色替換 ---
  def self.batch_apply_solid_colors(data)
    mappings = data['mappings']
    return UI.messagebox("錯誤：找不到 mappings") unless mappings
    sel = Sketchup.active_model.selection
    model = Sketchup.active_model
    model.start_operation('AI Fast Color Prep', true) 
    tag_to_material_hash = {}

    mappings.each do |map|
      new_mat = model.materials.add("AI_#{map['target_tag']}_#{Time.now.to_i}")
      new_mat.color = Sketchup::Color.new(map['hex_color'] || "#CCCCCC")
      tag_to_material_hash[map['target_tag']] = new_mat
    end
    self.apply_materials_to_tags(sel, "Untagged", tag_to_material_hash)
    model.commit_operation
    UI.messagebox("⚡ 分色完成！可按 Ctrl+Z 復原。")
  end

  def self.apply_materials_to_tags(entities, parent_layer_name, tag_hash)
    entities.each do |ent|
      effective_layer = (ent.layer.name == "Layer0" || ent.layer.name == "Untagged") ? parent_layer_name : ent.layer.name
      if ent.is_a?(Sketchup::Face)
        ent.material = tag_hash[effective_layer] if tag_hash[effective_layer]
      elsif ent.is_a?(Sketchup::Group)
        self.apply_materials_to_tags(ent.entities, effective_layer, tag_hash)
      elsif ent.is_a?(Sketchup::ComponentInstance)
        self.apply_materials_to_tags(ent.definition.entities, effective_layer, tag_hash)
      end
    end
  end
end

ArchitechAIAssistant_v6.open_assistant