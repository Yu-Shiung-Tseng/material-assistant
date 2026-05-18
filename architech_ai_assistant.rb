require 'sketchup.rb'
require 'json'

module ArchitechAIAssistant_v7
  @dialog = nil

  def self.open_assistant
    @dialog = UI::HtmlDialog.new({
      :dialog_title => "BIM AI Assistant - 語意雙引擎 v7.0",
      :width => 520, :height => 820,
      :style => UI::HtmlDialog::STYLE_DIALOG
    })

    html = <<-HTML
      <html>
        <head>
          <style>
            body { font-family: 'Segoe UI', sans-serif; padding: 15px; background: #f4f4f4; color: #333; }
            .card { background: white; padding: 15px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 20px; }
            textarea { width: 100%; height: 100px; font-family: monospace; font-size: 11px; margin: 10px 0; border: 1px solid #ccc; padding: 8px; box-sizing: border-box; background: #282c34; color: #abb2bf; }
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
            <span class="badge">保留設計師標註！僅針對未命名幾何體分類</span>
            <button class="btn-magic" onclick="sketchup.auto_tag_geometry()">✨ 智慧修復未分類幾何</button>
          </div>
          
          <div class="card">
            <h4>Step 2: 語意與圖層掃描 (Semantic Scanner)</h4>
            <button class="btn-scan" onclick="sketchup.scan_selection()">🔍 掃描模型標註與圖層</button>
            <textarea id="out_data" readonly placeholder="包含群組/組件名稱的結果將顯示於此..."></textarea>
            <button class="btn-scan" style="background:#6c757d;" onclick="copyData()">複製清單給 AI</button>
          </div>

          <div class="card">
            <h4>Step 3: AI 材質賦能 (Material Applier)</h4>
            <textarea id="in_data" placeholder='貼上 AI 給的 JSON (須包含 target_id 與 render_material_name)...'></textarea>
            <button class="btn-apply" onclick="applyBatch()">🎨 執行精準材質變更</button>
          </div>
          <script>
            window.updateUI = function(data) { document.getElementById('out_data').value = JSON.stringify(data, null, 2); };
            function copyData() { const el = document.getElementById("out_data"); el.select(); document.execCommand("copy"); alert("已複製！"); }
            function applyBatch() { 
              const val = document.getElementById('in_data').value;
              try { sketchup.process_batch(JSON.parse(val)); } catch(e) { alert("JSON 格式錯誤！請檢查。"); }
            }
          </script>
        </body>
      </html>
    HTML

    @dialog.set_html(html)
    @dialog.add_action_callback("auto_tag_geometry") { |_, _| self.execute_auto_tagger }
    @dialog.add_action_callback("scan_selection") { |_, _| self.execute_tag_scan }
    @dialog.add_action_callback("process_batch") { |_, params| self.batch_apply_materials(params) }
    @dialog.show
  end

  # --- 輔助方法：獲取群組或組件的名稱 ---
  def self.get_entity_name(ent)
    return ent.name if ent.is_a?(Sketchup::Group) && !ent.name.empty?
    return (ent.name.empty? ? ent.definition.name : ent.name) if ent.is_a?(Sketchup::ComponentInstance)
    return ""
  end

  # --- Step 1：智慧體檢 (尊重設計師標註版) ---
  def self.execute_auto_tagger
    model = Sketchup.active_model; sel = model.selection
    return UI.messagebox("請框選要進行體檢的模型！") if sel.empty?

    model.start_operation('AI Auto Tagging', true)
    @layers = { wall: model.layers.add("AI_Auto_Wall"), floor: model.layers.add("AI_Auto_Floor") }
    @stats = { wall: 0, floor: 0, skipped_named: 0 }
    
    self.recursive_auto_tag(sel, "")
    model.commit_operation
    UI.messagebox("✨ 體檢完成！\n已保護設計師命名物件: #{@stats[:skipped_named]} 面\n新標記牆壁: #{@stats[:wall]} 面\n新標記地板: #{@stats[:floor]} 面")
  end

  def self.recursive_auto_tag(entities, parent_name)
    entities.each do |ent|
      ent_name = self.get_entity_name(ent)
      current_name = ent_name.empty? ? parent_name : ent_name

      if ent.is_a?(Sketchup::Face)
        # 【核心修正】：如果這個面屬於有命名的群組/組件，絕對不要 Auto-Tag！
        if !current_name.empty?
          @stats[:skipped_named] += 1
          next
        end

        nz = ent.normal.z
        if nz.abs < 0.15; ent.layer = @layers[:wall]; @stats[:wall] += 1
        elsif nz > 0.85; ent.layer = @layers[:floor]; @stats[:floor] += 1
        end
      elsif ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
        child_entities = ent.is_a?(Sketchup::Group) ? ent.entities : ent.definition.entities
        self.recursive_auto_tag(child_entities, current_name)
      end
    end
  end

  # --- Step 2：語意與圖層掃描 ---
  def self.execute_tag_scan
    sel = Sketchup.active_model.selection
    return UI.messagebox("請先用滑鼠框選模型！") if sel.empty?
    @stats_hash = {}; @total_faces = 0
    self.dig_and_scan(sel, "Untagged", "")
    
    export_data = { 
      "action": "analyze_scene_by_elements", 
      "total_faces": @total_faces, 
      "elements_in_scene": @stats_hash.map { |k, v| { "target_id": k, "face_count": v } } 
    }
    @dialog.execute_script("updateUI(#{export_data.to_json})")
  end

  def self.dig_and_scan(entities, parent_tag, parent_name)
    entities.each do |ent|
      current_tag = (ent.layer.name == "Layer0" || ent.layer.name == "Untagged") ? parent_tag : ent.layer.name
      ent_name = self.get_entity_name(ent)
      current_name = ent_name.empty? ? parent_name : ent_name

      if ent.is_a?(Sketchup::Face)
        id = "[Tag: #{current_tag}] #{current_name}".strip
        id = "[未標註的散落幾何體]" if id == "[Tag: Untagged]" || id == "[Tag: Layer0]"
        
        @total_faces += 1
        @stats_hash[id] ||= 0
        @stats_hash[id] += 1
      elsif ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
        child_entities = ent.is_a?(Sketchup::Group) ? ent.entities : ent.definition.entities
        self.dig_and_scan(child_entities, current_tag, current_name)
      end
    end
  end

  # --- Step 3：AI 精準材質變更 ---
  def self.batch_apply_materials(data)
    mappings = data['mappings']
    return UI.messagebox("錯誤：JSON 格式錯誤，找不到 mappings") unless mappings
    
    sel = Sketchup.active_model.selection
    model = Sketchup.active_model
    model.start_operation('AI Material Apply', true) 
    
    tag_to_material_hash = {}

    mappings.each do |map|
      # 【核心修正】：用 AI 給的材質名稱建立 SketchUp 材質，讓渲染器能讀取！
      mat_name = map['render_material_name'] || "Color"
      clean_name = mat_name.gsub(/[^0-9a-zA-Z\u4e00-\u9fa5]/, '_') # 確保名稱合法
      
      new_mat = model.materials.add("AI_#{clean_name}_#{Time.now.to_i}")
      new_mat.color = Sketchup::Color.new(map['hex_color'] || "#CCCCCC")
      tag_to_material_hash[map['target_id']] = new_mat
    end

    self.apply_materials(sel, "Untagged", "", tag_to_material_hash)
    model.commit_operation
    UI.messagebox("⚡ 變更完成！材質已注入語意名稱供渲染器辨識。")
  end

  def self.apply_materials(entities, parent_tag, parent_name, tag_hash)
    entities.each do |ent|
      current_tag = (ent.layer.name == "Layer0" || ent.layer.name == "Untagged") ? parent_tag : ent.layer.name
      ent_name = self.get_entity_name(ent)
      current_name = ent_name.empty? ? parent_name : ent_name

      if ent.is_a?(Sketchup::Face)
        id = "[Tag: #{current_tag}] #{current_name}".strip
        id = "[未標註的散落幾何體]" if id == "[Tag: Untagged]" || id == "[Tag: Layer0]"
        
        ent.material = tag_hash[id] if tag_hash[id]
      elsif ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
        child_entities = ent.is_a?(Sketchup::Group) ? ent.entities : ent.definition.entities
        self.apply_materials(child_entities, current_tag, current_name, tag_hash)
      end
    end
  end
end

ArchitechAIAssistant_v7.open_assistant