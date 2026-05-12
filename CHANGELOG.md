# Changelog - Architech AI Assistant

所有關於 **Architech AI 智能材質助手** 的重要更新細節都將記錄在此文件中。

## [3.1.0] - 2026-05-12
### Added
- **Batch Rendering Engine (批次渲染引擎)**：支援一次性下載多組網路貼圖並根據映射表 (Mapping) 自動執行大規模替換。
- **Timestamped Mutation (材質變異追蹤)**：材質名稱自動加上 `AI_` 前綴與時間戳記，建立修改軌跡並避免材質命名衝突。
- **Graceful Error Handling (優化容錯機制)**：導入診斷警告視窗，當網路資源 (404) 或重新導向失效時，會精準條列失效圖層而非靜默失敗或導致程式當機。

### Fixed
- **UI 狀態同步**：動態讀取 JSON 中的 `style_name`，修正原本寫死 (Hardcoded) 的風格提示文字。
- **幾何過濾優化**：在掃描與渲染邏輯中，能夠更好地識別並穩定處理大規模場景數據。

---

## [2.0.0] - 2026-05-11
### Added
- **Recursive Traversal (遞歸遍歷演算法)**：開發深度挖掘引擎，可穿透無限層級的群組 (Groups) 與組件 (Components)，處理真實世界的複雜模型數據。
- **Scene Analysis Schema (場景分析協定)**：定義標準化 JSON 輸出格式，統計全域材質分布與幾何面數。

### Engineering Focus
- **幾何壓力測試**：成功通過單一選取區超過 390,000 個幾何面的深度掃描測試，確保演算法在大型專案中的穩定性。

---

## [1.0.0] - 2026-05-10
### Added
- **Ruby-HTML Bridge (雙向通訊橋接)**：使用 `UI::HtmlDialog` 實作 Web 與 SketchUp Ruby API 的非同步通訊介面。
- **Smart Download Engine (智能下載引擎)**：導入 `Net::HTTP` 搭配 **User-Agent Spoofing (瀏覽器偽裝)**，繞過常見圖庫伺服器的爬蟲防禦機制。
- **Defensive Programming (防禦性編程)**：實作 `nil?` 檢查機制，防止因網路請求失敗導致的 `nil:NilClass` 核心崩潰。

---

## [Future Roadmap]
### 🎯 近期開發目標
1. **Tag-Driven Mapping (圖層驅動映射)**：將掃描邏輯從「現有材質」轉向「SketchUp 圖層 (Tags)」，實現素模一鍵全屋自動換裝。
2. **Local Asset Library (本地化材質庫)**：開發本地路徑讀取功能，徹底解決網路圖片不穩定與 404 報錯痛點。
3. **Transaction Undo (一鍵復原)**：將批次變更封裝進單一 `start_operation`，支援 Ctrl+Z 一鍵撤銷大規模風格替換。
