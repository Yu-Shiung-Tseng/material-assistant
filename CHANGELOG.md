# Changelog - BIM AI Assistant

所有關於 **BIM AI 智能材質助手** 的重要更新細節都將記錄在此文件中。

## [7.0.0] - 2026-05-18
### Added
- **Semantic Shield (語意盾牌機制)**：升級 Auto-Tagger 引擎。系統掃描時會自動讀取並保護設計師手動命名的群組 (Group) 與組件 (Component) 名稱。被命名的物件將被豁免於自動幾何分類，徹底解決窗戶/欄杆被誤判為牆壁的實務痛點。
- **PBR Material Injection (物理材質關鍵字注入)**：AI 映射腳本新增 `render_material_name` 屬性。系統現在不僅能替換顏色，還能使用帶有物理材質關鍵字（如 Iron, Wood, Glass）的名稱在 SketchUp 中建立真實材質，達成與 Enscape / Lumion 渲染器的完美對接。

---

## [6.0.0] - 2026-05-15
### Added
- **Auto-Tagger Engine (智能分類引擎)**：導入「幾何特徵啟發式辨識 (Heuristic Geometry Recognition)」，透過計算 3D 面的法向量 (Normal Vector) 在 Z 軸上的分量，自動將 `Untagged` (未標記) 的雜亂素模精準分類為 `AI_Auto_Wall`、`AI_Auto_Floor` 與 `AI_Auto_Ceiling`。
- **Smart Area Filter (智慧面積過濾)**：體檢掃描過程中，自動略過面積過小（預設 < 100 sq inch）的零碎幾何面，確保自動分類圖層的純淨度。

---

## [5.0.0] - 2026-05-14
### Added
- **Solid-Color Prep Engine (極速離線純色引擎)**：專為對接後端渲染器 (如 Lumion, Enscape) 設計。徹底拔除外部網路圖片 (`Net::HTTP`) 依賴，改用 Hex 色碼直接生成 SketchUp 內建純色材質，達成 100% 離線穩定度與毫秒級執行效能。
- **Transaction Undo (全域事務復原)**：將批次換色邏輯封裝入單一 `model.start_operation` 事務中，全面支援 `Ctrl + Z` 一鍵復原。

---

## [4.0.0] - 2026-05-13
### Added
- **Tag-Driven Mapping (圖層驅動映射)**：系統核心邏輯由「比對材質名稱」轉型為「比對圖層標籤 (Tags)」，完美契合 BIM 標準工作流。
- **Layer Inheritance (圖層繼承穿透)**：升級遞歸掃描引擎，支援讀取父群組圖層屬性。

---

## [3.1.0] - 2026-05-12
### Added
- **Batch Rendering Engine (批次渲染引擎)**：支援一次性下載多組網路貼圖並替換。
- **Timestamped Mutation (材質變異追蹤)**：材質名稱自動加上 `AI_` 前綴與時間戳記。
- **Graceful Error Handling (優化容錯機制)**：導入診斷警告視窗。

---

## [2.0.0] - 2026-05-11
### Added
- **Recursive Traversal (遞歸遍歷演算法)**：深度挖掘引擎，可穿透無限層級的群組與組件。
- **Scene Analysis Schema (場景分析協定)**：定義標準化 JSON 輸出格式。

---

## [1.0.0] - 2026-05-10
### Added
- **Ruby-HTML Bridge (雙向通訊橋接)**：使用 `UI::HtmlDialog` 實作非同步通訊。
- **Smart Download Engine (智能下載引擎)**：繞過常見圖庫伺服器防禦機制。
- **Defensive Programming (防禦性編程)**：實作 `nil?` 檢查機制。
