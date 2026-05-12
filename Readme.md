Architech AI Assistant (v3.1)
Architech AI Assistant 是一款專為 SketchUp 開發的智能材質管理外掛。透過 Ruby API 與 AI 邏輯的結合，本工具能大幅縮減建築師在模型後期處理（材質替換與渲染準備）上的重複勞動，將原本需要數小時的手動點擊過程縮短至秒級自動化處理。

🚀 核心功能
深度場景掃描 (Deep Scene Scanner)：採用遞歸遍歷演算法 (Recursive Traversal)，能穿透模型中複雜的群組 (Groups) 與組件 (Components) 嵌套，精準統計全域幾何面數據。

智能材質映射 (Smart Material Mapping)：支援透過 JSON 指令進行大規模材質替換，並自動為新材質添加時間戳記軌跡，避免命名衝突。

強健的渲染引擎 (Robust Render Engine)：內建防禦性編程邏輯，支援網路貼圖非同步下載、瀏覽器偽裝 (User-Agent Spoofing) 以及失效連結的自動攔截與診斷警告。

Web-Base 交互介面：使用 HTML/JS 構建輕量化控制面板，實現流暢的跨平台資料交換。

🛠️ 技術棧
後端核心：Ruby (SketchUp API)

前端介面：HTML5, CSS3, JavaScript (ES6)

資料格式：JSON

網路通訊：Ruby Net::HTTP, URI, Tempfile

📖 使用指南
載入外掛：將 architech_ai_assistant.rb 貼入 SketchUp Ruby Console 執行。

場景掃描：框選模型物件後，點擊「🔍 掃描框選區域」。系統將生成該區塊的材質分佈 JSON。

AI 風格化：將 JSON 提供給 AI，獲得風格映射表。

批次換裝：將 AI 回傳的 Mapping JSON 貼入下方輸入框，按下「🎨 執行全區自動換裝」。

🚧 未來優化方向 (Roadmap)
為了進一步減輕建築師的 Loading 並提升系統穩定度，後續開發將聚焦於以下四個維度：

1. 圖層驅動工作流 (Tag-Driven Mapping)
目前系統依賴「現有材質名稱」進行分類。未來計畫優化為 「根據圖層 (Tags) 映射」。

場景：建築師只需將素模物件放入 Wall 或 Floor 圖層，外掛即可一鍵完成全屋材質填充，無需事先上色。

2. 本地材質庫集成 (Local Asset Library)
為了解決網路貼圖穩定性 (404 報錯) 與下載延遲問題。

優化：開發路徑解析模組，支援從本地磁碟直接讀取建築師常用的高品質材質庫，達成 100% 的渲染成功率。

3. 事後回溯機制 (Transaction Undo)
優化：將大規模批次變更封裝進單一 start_operation 事務中。

價值：確保使用者可以透過 Ctrl + Z 一鍵復原所有自動化變更，提升操作安全性。

4. 智慧過濾與預覽 (Smart Filtering & Preview)
優化：自動識別並排除非建築結構材質（如比例人物 Sree_、玻璃、光源）。

優化：在執行批次換裝前，於介面顯示材質縮圖預覽，提升 UX 體驗。