# Changelog - Architech AI Assistant

所有關於 **Architech AI 智能材質助手** 的重要更新細節都將記錄在此文件中。

## [6.0.0] - 2026-05-15
### Added
- **Auto-Tagger Engine (智能分類引擎)**：導入「幾何特徵啟發式辨識 (Heuristic Geometry Recognition)」，透過計算 3D 面的法向量 (Normal Vector) 在 Z 軸上的分量，自動將 `Untagged` (未標記) 的雜亂素模精準分類為 `AI_Auto_Wall`、`AI_Auto_Floor` 與 `AI_Auto_Ceiling`。
- **Smart Area Filter (智慧面積過濾)**：體檢掃描過程中，自動略過面積過小（預設 < 100 sq inch）的零碎幾何面，確保自動分類圖層的純淨度。

---

## [5.0.0] - 2026-05-14
### Added
- **Solid-Color Prep Engine (極速離線純色引擎)**：專為對接後端渲染器 (如 Lumion, Enscape) 設計。徹底拔除外部網路圖片 (`Net::HTTP`) 依賴，改用 Hex 色碼 (e.g., `#FFFFFF`) 直接生成 SketchUp 內建純色材質，達成 100% 離線穩定度與毫秒級執行效能。
- **Transaction Undo (全域事務復原)**：將批次換色邏輯封裝入單一 `model.start_operation` 事務中，全面支援 `Ctrl + Z` 一鍵復原所有（高達數十萬面）的修改。

---

## [4.0.0] - 2026-05-13
### Added
- **Tag-Driven Mapping (圖層驅動映射)**：系統核心邏輯由「比對材質名稱」轉型為「比對圖層標籤 (Tags)」，完美契合 BIM (建築資訊模型) 標準工作流，支援全素模一鍵自動換裝。
- **Layer Inheritance (圖層繼承穿透)**：升級遞歸掃描引擎，若幾何面位於 `Layer0` 或 `Untagged`，將自動往上層追溯並繼承父群組 (Group/Component) 的圖層屬性。

---

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
1. **UI/UX 智慧預覽 (Smart Preview)**：在 HTML 面板中加入 Hex 色碼色塊預覽功能，讓使用者在執行套用前能直觀確認 AI 分配的色彩策略。
2. **AI Component Recognition (智能組件識別)**：從單純的「面法向量」辨識，進階到辨識「門、窗、樓梯」等複合幾何特徵組件。
3. **Export to Renderers (渲染器一鍵匯出)**：建立與 Enscape/V-Ray 等主流渲染軟體的直接材質聯動設定。
