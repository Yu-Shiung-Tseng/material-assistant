# BIM AI Assistant (v7.0) - Semantic & Geometric Dual Engine

**BIM AI Assistant** 是一款專為 SketchUp 與後端渲染器 (Enscape/Lumion) 設計的智能化材質與圖層管理外掛。
在最新的 v7.0 版本中，系統導入了**「語意與幾何雙引擎 (Semantic & Geometric Engine)」**。不僅能透過數學向量自動辨識未標記的幾何體，更加入了「語意盾牌」機制，完美保留設計師的自訂群組命名，並利用 AI 注入物理材質關鍵字，實現從建模到渲染的無縫對接。

## 🚀 核心亮點 (Core Features)

### 1. 語意與幾何雙擎體檢 (Dual Engine Auto-Tagger)
* **語意盾牌 (Semantic Shield)**：自動讀取並保護使用者設定的群組/組件名稱 (如「門」、「窗戶」、「欄杆」)，避免被系統誤判覆蓋。
* **幾何特徵辨識 (Vector Math)**：針對未命名的 `Untagged` 素模，透過法向量 (Normal Vector) 分析，自動歸類出 `AI_Auto_Wall` (牆壁) 與 `AI_Auto_Floor` (地板)。

### 2. 物理渲染材質注入 (PBR Material Injection)
打破過去「只有顏色、沒有質感」的限制。AI 現在會生成如 `Black_Iron` 或 `Yellow_Tile` 的渲染材質名稱 (`render_material_name`)，SketchUp 接收後會以此名稱建立材質，讓 Enscape 或 Lumion 等渲染引擎能自動賦予金屬反光或凹凸紋理。

### 3. 極速離線引擎與全域復原 (Offline Engine & Undo)
* **100% 穩定度**：無須依賴網路圖片下載，毫秒級產生全域色塊映射。
* **防呆機制**：所有操作皆封裝於單一 `start_operation` 事務中，隨時可按 `Ctrl + Z` 一鍵復原。

## 📖 標準工作流 (The BIM Workflow)

1. **物件命名 (Optional)**：在 SketchUp 中將特殊物件 (如門、窗、欄杆) 群組並命名，系統會優先保護這些標註。
2. **體檢與分類**：框選模型，點擊 **「✨ 智慧修復未分類幾何」**，系統將自動補齊牆壁與地板的標籤。
3. **掃描結構**：點擊 **「🔍 掃描模型標註與圖層」**，獲取包含語意標籤的結構清單。
4. **AI 賦能**：將清單交給 AI 助理（需搭配 v7.0 專屬 System Prompt），輸入設計需求（例如：牆壁用二丁掛，欄杆用黑鐵）。
5. **極速材質套用**：將 AI 回傳的 JSON 貼入外掛，點擊執行，瞬間完成具備物理材質語意的渲染前置作業。

## 📂 版本演進軌跡 (Evolution Roadmap)

* **v1.0**：打通 Ruby 與 HTML 雙向通訊，實作基礎材質抓取。
* **v3.1**：實作遞歸掃描，處理 39 萬面髒數據。
* **v5.0**：改用 Hex 色碼引擎，達成極速離線渲染預備與事務復原 (Undo)。
* **v6.0**：導入幾何法向量辨識，實作 Auto-Tagger 自動分類器。
* **v7.0**：導入「語意盾牌」保護設計師標註，並支援渲染引擎物理材質關鍵字 (PBR Name Injection) 注入。

---

**Author:** Tseng Yu Shiang (Doban)
**Current Version:** v7.0.0 (Semantic & Geometric Engine)
**Release Date:** 2026-05-18
