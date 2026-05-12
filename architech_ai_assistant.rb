require 'sketchup.rb'
require 'json'
require 'net/http'
require 'tempfile'
require 'uri'

module ArchitechAI_Assistant
  @dialog = nil

  def self.open_assistant
    # (UI 介面保持不變，為節省版面省略 HTML 部分的修改，維持原樣)
    @dialog = UI::HtmlDialog.new({
      :dialog_title => "Architech AI - 智能材質助手",
      :width => 450, :height => 600,
      :style => UI::HtmlDialog::STYLE_DIALOG
    })

    html = <<-HTML
      <html>
        <head>
          <style>
            body { font-family: 'Segoe UI', sans-serif; padding: 15px; background: #f4f4f4; color: #333; }
            .card { background: white; padding: 15px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 20px; }
            textarea { width: 100%; height: 80px; font-family: monospace; font-size: 12px; margin: 10px 0; border: 1px solid #ccc; border-radius: 4px; padding: 5px; box-sizing: border-box; }
            button { width: 100%; padding: 10px; border: none; border-radius: 4px; cursor: pointer; font-weight: bold; margin-bottom: 5px; }
            .btn-fetch { background: #007bff; color: white; }
            .btn-copy { background: #6c757d; color: white; }
            .btn-apply { background: #28a745; color: white; margin-top: 10px; }
            h4 { margin: 0 0 10px 0; color: #444; }
          </style>
        </head>
        <body>
          <div class="card">
            <h4>1. 取得物件資訊給 AI</h4>
            <button class="btn-fetch" onclick="sketchup.fetch_selection()">⚡ 抓取目前選取的面</button>
            <textarea id="out_data" readonly></textarea>
            <button class="btn-copy" onclick="copyData()">複製 JSON 給 AI</button>
          </div>

          <div class="card">
            <h4>2. 貼上 AI 生成的材質參數</h4>
            <textarea id="in_data" placeholder='請將 AI 回傳的 JSON 貼在這裡...'></textarea>
            <button class="btn-apply" onclick="applyTexture()">🎨 執行 AI 貼圖下載與渲染</button>
          </div>

          <script>
            window.updateUI = function(data) { document.getElementById('out_data').value = JSON.stringify(data, null, 2); };
            function copyData() { const el = document.getElementById("out_data"); el.select(); document.execCommand("copy"); alert("已複製！"); }
            function applyTexture() { 
              const val = document.getElementById('in_data').value;
              try { sketchup.process_ai_texture(JSON.parse(val)); } catch(e) { alert("JSON 格式錯誤"); }
            }
          </script>
        </body>
      </html>
    HTML

    @dialog.set_html(html)
    @dialog.add_action_callback("fetch_selection") { |_, _| self.export_face_info }
    @dialog.add_action_callback("process_ai_texture") { |_, params| self.download_and_apply(params) }
    @dialog.show
  end

  def self.export_face_info
    sel = Sketchup.active_model.selection
    return UI.messagebox("請先選取一個面！") if sel.empty?
    target = sel[0]
    return UI.messagebox("請確保選到的是「面」") if !target.is_a?(Sketchup::Face)
    data = { "id" => target.entityID, "type" => "Face", "area_sqin" => target.area.to_f.round(2) }
    @dialog.execute_script("updateUI(#{data.to_json})")
  end

  # 🚀 強化版下載邏輯
  def self.download_and_apply(data)
    url = data['texture_url']
    width = data['width_cm'] || 150
    return UI.messagebox("錯誤：缺少 texture_url") if url.nil? || url.empty?

    begin
      Sketchup.set_status_text("🔄 AI 材質下載中...")
      
      uri = URI.parse(url)
      temp_file = Tempfile.new(['ai_texture', '.jpg'])
      temp_file.binmode
      
      # 1. 偽裝成瀏覽器 (User-Agent)
      req = Net::HTTP::Get.new(uri)
      req['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
        resp = http.request(req)
        # 2. 檢查伺服器是否允許下載
        if resp.is_a?(Net::HTTPSuccess)
          temp_file.write(resp.body)
        else
          raise "伺服器拒絕存取 (#{resp.code})，請換一個圖片網址"
        end
      end
      temp_file.close

      model = Sketchup.active_model
      model.start_operation('AI Render Material', true)
        
        new_mat = model.materials.add("AI_Mat_#{Time.now.to_i}")
        new_mat.texture = temp_file.path
        
        # 3. 防呆檢查：圖片是否有成功載入？
        if new_mat.texture.nil?
          raise "下載的檔案不是有效的圖片格式！"
        end

        new_mat.texture.size = width.cm 
        
        model.selection.each do |ent|
          ent.material = new_mat if ent.respond_to?(:material=)
        end

      model.commit_operation
      UI.messagebox("✅ 材質渲染成功！")
      
    rescue => e
      UI.messagebox("❌ 執行失敗：#{e.message}")
    ensure
      temp_file.unlink if temp_file
    end
  end
end

ArchitechAI_Assistant.open_assistant