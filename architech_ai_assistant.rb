require 'sketchup.rb'
require 'json'
require 'net/http'
require 'tempfile'
require 'uri'

module ArchitechAIAssistant
  @dialog = nil

  def self.open_assistant
    @dialog = UI::HtmlDialog.new({
      :dialog_title => "Architech AI - 智能空間管理器 v3.1",
      :width => 500, :height => 750,
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
            .btn-scan { background: #6f42c1; color: white; }
            .btn-copy { background: #6c757d; color: white; }
            .btn-apply { background: #28a745; color: white; margin-top: 5px; }
            h4 { margin: 0 0 5px 0; color: #444; border-bottom: 2px solid #eee; padding-bottom: 5px; }
          </style>
        </head>
        <body>
          <div class="card">
            <h4>1. 深度掃描 (Scene Scanner)</h4>
            <button class="btn-scan" onclick="sketchup.scan_selection()">🔍 掃描框選區域</button>
            <textarea id="out_data" readonly></textarea>
            <button class="btn-copy" onclick="copyData()">複製給 AI</button>
          </div>
          <div class="card">
            <h4>2. 批次風格替換 (Batch Render)</h4>
            <textarea id="in_data" placeholder='貼上 AI 給的 Mappings JSON...'></textarea>
            <button class="btn-apply" onclick="applyBatch()">🎨 執行全區自動換裝</button>
          </div>
          <script>
            window.updateUI = function(data) { document.getElementById('out_data').value = JSON.stringify(data, null, 2); };
            function copyData() { const el = document.getElementById("out_data"); el.select(); document.execCommand("copy"); alert("已複製！"); }
            function applyBatch() { 
              const val = document.getElementById('in_data').value;
              try { sketchup.process_batch(JSON.parse(val)); } catch(e) { alert("JSON 格式錯誤"); }
            }
          </script>
        </body>
      </html>
    HTML

    @dialog.set_html(html)
    @dialog.add_action_callback("scan_selection") { |_, _| self.execute_deep_scan }
    @dialog.add_action_callback("process_batch") { |_, params| self.batch_apply_textures(params) }
    @dialog.show
  end

  # --- 功能 1：深度掃描 ---
  def self.execute_deep_scan
    sel = Sketchup.active_model.selection
    return UI.messagebox("請先用滑鼠框選模型區域！") if sel.empty?

    Sketchup.set_status_text("🔄 正在深度掃描幾何體...")
    @all_faces = []
    self.dig_into_entities(sel)
    return UI.messagebox("找不到面！") if @all_faces.empty?

    stats = {}
    @all_faces.each do |face|
      mat_name = face.material ? face.material.name : "未上色_Default"
      stats[mat_name] ||= { count: 0 }
      stats[mat_name][:count] += 1
    end

    export_data = {
      "action": "analyze_scene",
      "total_faces_found": @all_faces.length,
      "materials_in_scene": stats.map { |k, v| { "original_material": k, "face_count": v[:count] } }
    }
    @dialog.execute_script("updateUI(\#{export_data.to_json})")
    Sketchup.set_status_text("✅ 掃描完成！")
  end

  def self.dig_into_entities(entities)
    entities.each do |ent|
      if ent.is_a?(Sketchup::Face)
        @all_faces << ent
      elsif ent.is_a?(Sketchup::Group)
        self.dig_into_entities(ent.entities)
      elsif ent.is_a?(Sketchup::ComponentInstance)
        self.dig_into_entities(ent.definition.entities)
      end
    end
  end

  # --- 功能 2：批次下載與替換 ---
  def self.batch_apply_textures(data)
    mappings = data['mappings']
    style_name = data['style_name'] || "新風格" 
    return UI.messagebox("錯誤：找不到 mappings 陣列") unless mappings

    @all_faces = []
    self.dig_into_entities(Sketchup.active_model.selection)
    
    model = Sketchup.active_model
    model.start_operation('Batch AI Render', true)
    
    failed_downloads = []

    begin
      mappings.each do |map|
        target_mat = map['target_material']
        url = map['texture_url']
        width = map['width_cm'] || 200

        Sketchup.set_status_text("🔄 下載材質中: \#{target_mat}...")
        
        uri = URI.parse(url)
        temp_file = Tempfile.new(['ai_mat', '.jpg'])
        temp_file.binmode
        
        req = Net::HTTP::Get.new(uri)
        req['User-Agent'] = 'Mozilla/5.0'
        
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
          resp = http.request(req)
          temp_file.write(resp.body) if resp.is_a?(Net::HTTPSuccess)
        end
        temp_file.close

        new_mat = model.materials.add("AI_\#{target_mat}_\#{Time.now.to_i}")
        
        begin
          new_mat.texture = temp_file.path
        rescue StandardError
          # 捕捉無效圖片格式的錯誤
        end

        if new_mat.texture.nil?
          failed_downloads << target_mat
          temp_file.unlink
          next
        end

        new_mat.texture.size = width.cm 

        @all_faces.each do |face|
          current_mat = face.material ? face.material.name : "未上色_Default"
          if current_mat == target_mat
            face.material = new_mat
          end
        end
        
        temp_file.unlink
      end
      
      model.commit_operation

      final_message = "✅ \#{style_name}，變裝完成！"
      if failed_downloads.any?
        final_message += "\n\n⚠️ 警告：以下材質因網路或圖片失效下載失敗，已跳過：\n\#{failed_downloads.join(', ')}"
      end

      UI.messagebox(final_message)
      Sketchup.set_status_text("✅ 批次渲染結束")
      
    rescue => e
      model.abort_operation
      UI.messagebox("❌ 發生錯誤：\#{e.message}")
    end
  end
end

ArchitechAIAssistant.open_assistant
