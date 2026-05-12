Smart Material Assistant (SketchUp Plugin)
這是一款專為 SketchUp 開發的智能材質橋接外掛，旨在將 3D 模型幾何資訊與生成式 AI 流程整合。透過 Ruby API 與 Web 技術（HtmlDialog）的雙向溝通，實現從物理空間數據到 AI 材質渲染的自動化工作流。

🚀 核心功能
物理幾何提取：自動辨識並導出選取面的 ID、幾何類型（Face/Edge）與物理面積。

AI 材質映射：接收 AI 產生的 JSON 指令，自動處理雲端貼圖下載。

智能比例控制：動態設定貼圖物理尺寸（UV Scaling），確保渲染結果符合現實比例。

健壯的下載引擎：具備 User-Agent 偽裝機制，可繞過常見圖庫伺服器的爬蟲防禦。

🛠️ 技術決策與工程亮點 (Engineering Judgment)
在開發這個 MVP (最小可行性產品) 的過程中，我針對多個技術難點進行了權衡與處理：

1. 數據交換協定 (Schema-First Design)
為了實現 SketchUp 與 AI 助手之間的解耦，我設計了一套輕量級的 JSON 通訊協定。

優點：確保了外掛核心邏輯與 AI 服務的高度分離，未來可無縫接入 Stable Diffusion 或 Midjourney 的 API。

2. 防禦性編程 (Defensive Programming)
在處理網路圖片下載時，開發初期遇到了伺服器回傳 403 Forbidden 或 404 Not Found 導致 SketchUp 核心崩潰（nil:NilClass 錯誤）的問題。

解決方案：

實作 User-Agent Spoofing：偽裝成瀏覽器請求以確保資源獲取率。

狀態攔截機制：在執行 texture.size= 前強制進行 nil? 檢查，確保程式的穩定性（Robustness）。

3. 同步下載的權衡
目前版本採用同步下載 (Net::HTTP) 配合暫存檔 (Tempfile) 處理。

工程判斷：雖然同步請求會短暫阻塞 SketchUp 主執行緒，但在處理單一材質時，這能保證操作的原子性（Atomicity），避免材質尚未下載完成就進行賦值的競爭風險。

📦 安裝與啟動
下載 architech_ai_assistant.rb。

在 SketchUp 中開啟 Ruby Console (Window > Ruby Console)。

將程式碼內容貼入並按下回車。

點擊選單：Extensions > Architech AI助手 > 開啟控制台。

📖 使用手冊 (Workflow)
選取目標：在 SketchUp 進入編輯模式，點選欲替換材質的面（Face）。

提取資訊：在視窗中點擊 ⚡ 抓取目前選取的面。

AI 溝通：將產出的 JSON 複製給 AI 助手，並附上您的材質需求（如：「我要清水模風格」）。

自動渲染：將 AI 回傳的 JSON 貼入下方的執行框，點擊 🎨 執行 AI 貼圖下載與渲染。

🗺️ 未來展望 (Roadmap)
[ ] 批次處理引擎：支援區域選取（Selection Collection），實現整區物件的風格遷移。

[ ] 非同步優化：引入 UI.start_timer 模擬非同步下載，消除介面卡頓。

[ ] 本地快取機制：減少重複材質的網路請求與磁碟 I/O。