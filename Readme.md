AI Assistant (v6.0) - Auto-Tagger Edition
Architech AI Assistant 是一款專為 SketchUp 開發的 BIM 智能化材質與圖層管理外掛。
從 v6.0 版本開始，系統不再只是被動地依賴使用者的建模習慣，而是具備了「幾何特徵啟發式辨識 (Heuristic Geometry Recognition)」的能力。透過底層的數學向量分析，系統能自動診斷並整理雜亂的素模，將原本繁瑣的渲染前置作業（分色、上材質）縮短至毫秒級，達成 100% 離線穩定運作。

🚀 核心亮點 (Core Features)
1. 智慧體檢與自動分類 (Auto-Tagger Engine)
打破「依賴使用者良好習慣」的限制。針對所有放置在 Untagged（未標記）圖層的雜亂模型，系統會透過掃描每個面的法向量 (Normal Vector) 進行特徵辨識：

牆壁 (Wall)：自動歸類 Z 軸分量趨近於 0 的垂直面。

地板/屋頂 (Floor/Ceiling)：自動歸類 Z 軸分量大於 0.85 或小於 -0.85 的水平面。

雜項過濾：自動略過面積過小（預設 < 100 sq inch）的瑣碎幾何體，確保 AI 分類的純淨度。

2. 極速離線純色引擎 (Solid-Color Prep Engine)
徹底拔除對外部網路貼圖 (URL) 的依賴。AI 現在只需回傳 HEX 色碼，系統便會瞬間在 SketchUp 內建材質庫產生對應的純色色塊並套用，作為後端渲染軟體 (如 Enscape, V-Ray, Lumion) 的辨識標籤。

100% 穩定度：沒有 404 報錯、沒有下載延遲。

毫秒級效能：即使處理百萬個面也極致流暢。

3. 全域事務管理 (Transaction Undo)
支援 Ctrl + Z 一鍵復原。所有大規模的圖層分類與材質替換，皆封裝於單一的 start_operation 事務中，確保使用者能無壓力地探索各種分色方案。

🛠️ 技術棧與架構
後端核心：Ruby (SketchUp API)

演算法：深度優先搜尋 (DFS 遞歸掃描)、3D 向量數學 (Vector Math)

前端介面：HTML5, CSS3, JavaScript (UI::HtmlDialog)

通訊協定：JSON (Action Callbacks)

📖 標準工作流 (The BIM Workflow)
體檢與分類：框選雜亂的素模，點擊 「✨ 一鍵智慧幾何分類」，讓 Ruby 幫你把牆壁和地板貼好隱形標籤 (AI_Auto_Wall, AI_Auto_Floor)。

掃描結構：點擊 「🔍 掃描框選區塊的圖層」，獲取整理後的圖層清單 JSON。

AI 賦能：將清單交給 AI（例如 ChatGPT/Gemini），用語意描述你想要的風格（如：日式清水模、工業風）。

極速分色：將 AI 回傳的 Hex Code JSON 貼入系統，按下 「🎨 執行圖層分色」，瞬間完成渲染前置作業。

📂 版本演進軌跡 (Evolution Roadmap)
v1.0：打通 Ruby 與 HTML 雙向通訊，實作基礎材質抓取。

v2.0:從單一物件變更圖層，轉成判斷使用者框選的內容批量變更圖層。

v3.1：實作遞歸掃描處理 39 萬面髒數據，並加入網路下載的容錯機制。

v4.0：從「材質映射」轉向「圖層驅動 (Tag-Driven)」，貼近 BIM 標準工作流。

v5.0：移除網路圖片依賴，改用 Hex 色碼，達成極速離線渲染預備。

v6.0：導入幾何法向量辨識，實作 Auto-Tagger 自動分類器，解決「使用者未分類圖層」的痛點。