# UniTally 鸿蒙版 - 项目记忆文件

> 最后更新: 2026-06-21
> 状态: 全部功能已完成，编译通过，功能可交互

---

## 一、项目概况

- **目标**: 将 Web 版 UniTally 记账应用迁移到华为鸿蒙 (HarmonyOS) 原生平台
- **IDE**: DevEco Studio 6.1.1
- **SDK**: HarmonyOS API 12 (compileSdkVersion "5.0.0(12)")
- **源项目**: `D:\UniTally_beta` (Web/TypeScript)
- **参考项目**: `D:\HUAWEI\UniTally` (鸿蒙原生，使用 CustomDialogController)
- **当前项目**: `D:\UniTallycodeing`
- **规格文件**: `D:\UniTallycodeing\UNIFALLY_SPEC.md`

---

## 二、架构设计

### 核心架构: Navigation + 自定义底栏 + DIALOG弹窗

```
Index.ets (单文件，~2200行)
├── @Entry @Component struct Index
│   ├── @Provide 数据: navStack, transactions, wallets, editTxId, editWalletId, budgets, subscriptions, editBudgetId, editSubId
│   ├── @State 缓存: walletBalanceCache, budgetSpentCache, monthExpenseTotal, monthCategoryDataCache, monthlyBarDataCache, calendarCellsCache
│   ├── Navigation(navStack)
│   │   ├── 内容区域: 4个Tab (Stack条件渲染)
│   │   │   ├── Tab 0: BookTab (明细大厅)
│   │   │   ├── Tab 1: AssetTab (我的资产)
│   │   │   ├── Tab 2: DashboardTab (数据看板)
│   │   │   └── Tab 3: CalendarTab (支出日历)
│   │   └── 底部导航栏: Stack(Row(Tab项) + 中心圆形"+"按钮)
│   └── @Builder PageMap: 路由映射
│       ├── 'EditRecord' → EditRecordPage
│       ├── 'EditWallet' → EditWalletPage
│       ├── 'EditBudget' → EditBudgetPage
│       ├── 'EditSubscription' → EditSubscriptionPage
│       └── 'Settings' → SettingsPage
├── EditRecordPage @Component (DIALOG弹窗)
├── EditWalletPage @Component (DIALOG弹窗)
├── EditBudgetPage @Component (DIALOG弹窗)
├── EditSubscriptionPage @Component (DIALOG弹窗)
└── SettingsPage @Component (DIALOG弹窗)
```

### 底部导航栏: Touch n' go 风格
- 4个Tab: 明细📋 / 资产💰 / 看板📊 / 日历📅
- 中心圆形"+"按钮: `.position({ x: '50%', y: 0 })` + `.markAnchor({ x: '50%', y: '50%' })`
- Stack容器需 `.clip(false)` 允许按钮溢出
- 按钮有蓝色阴影效果

### 数据流
- Index 持有全局 `@Provide` 数据
- 子组件通过 `@Consume` 获取和修改数据
- `@Watch` 装饰器监听数据变更，自动调用 `saveXxx()` 持久化
- `dataLoaded` 标志防止加载期间误触发保存

---

## 三、关键踩坑记录 (必须遵守)

### 1. APP_INPUT_BLOCK 根因
- **问题**: 复杂组件中使用 CustomDialogController / bindSheet / 条件渲染覆盖层导致主线程5秒内无法响应
- **根因**: 组件渲染复杂度导致主线程阻塞，弹窗/覆盖层让渲染节点翻倍
- **解决方案**: 使用 Navigation + NavDestinationMode.DIALOG，官方推荐替代 CustomDialogController
- **结论**: DIALOG模式的NavDestination默认透明背景，不影响下层Standard页面的显示和交互
- **重要**: 渲染中禁止遍历所有交易的计算方法（getWalletBalance/getBudgetSpent/getMonthExpense等），必须用缓存模式：computeXxx()仅在数据变更时调用，渲染中只读@State缓存变量（O(1)）

### 2. Navigation 白屏问题
- **问题**: `.hideNavBar(true)` 导致整个页面不渲染（白屏）
- **解决方案**: 改用 `.hideTitleBar(true)` + `.titleMode(NavigationTitleMode.Mini)` + `.title('')`
- **注意**: `.hideTitleBar(true)` 是 Navigation 的属性，`.hideNavBar(true)` 会导致白屏

### 3. ArkTS 严格模式限制
- **禁止**: `any`, `unknown`, 索引签名 `Record<string, T>` (变量声明)
- **JSON.parse**: 返回 `any`，必须立即用 `as Object[]` 或 `as Record<string, Object>` 类型断言
- **枚举与string**: `TransactionType` 是字符串枚举，但不能直接赋值给 `string` 变量。比较时用 `as string` 转换或用字符串字面量
- **@Builder函数参数**: 不支持函数类型参数如 `() => void`，需内联 onClick 逻辑
- **装饰器顺序**: `@Provide` 在前，`@Watch` 在后: `@Provide('x') @Watch('onXChanged') x: Type`

### 4. @Provide/@Consume 配对
- 子组件 `@Consume('budgets')` 必须在 Index 中有对应的 `@Provide('budgets')`
- 如果 Index 中是 `@State` 而非 `@Provide`，运行时必崩（找不到提供者）

### 5. 数据持久化时序
- `aboutToAppear` 中用 `setTimeout(() => { this.loadData() }, 100)` 延迟加载
- `dataLoaded = true` 在 `loadData` 完成后设置
- `@Watch` 回调中检查 `if (this.dataLoaded)` 才触发保存
- `initMockData()` 末尾手动调用 `saveTransactions()` / `saveWallets()`（因为此时 dataLoaded 还为 false）

---

## 四、文件结构

### 核心文件
| 文件 | 说明 |
|------|------|
| `entry/src/main/ets/pages/Index.ets` | 主页面，所有UI和逻辑（~2500行） |
| `entry/src/main/ets/model/Transaction.ets` | 交易模型 + `createTransactionFromJson` |
| `entry/src/main/ets/model/Wallet.ets` | 钱包模型 + `createWalletFromJson` + `getDisplayBalance()` |
| `entry/src/main/ets/model/Category.ets` | 分类模型 + `DEFAULT_EXPENSE_CATEGORIES` / `DEFAULT_INCOME_CATEGORIES` |
| `entry/src/main/ets/model/Budget.ets` | 预算模型 + `createBudgetFromJson` + `getUsagePercent()` / `isOverBudget()` |
| `entry/src/main/ets/model/Subscription.ets` | 订阅模型 + `createSubscriptionFromJson` + `isExpired()` / `getDaysRemaining()` |
| `entry/src/main/ets/model/Platform.ets` | 平台模型 |
| `entry/src/main/ets/constants/CurrencyConst.ets` | `TransactionType`/`WalletType` 枚举 + `getCurrencySymbol()` |
| `entry/src/main/ets/constants/I18n.ets` | 国际化 |
| `entry/src/main/ets/constants/UIStyleConst.ets` | UI风格常量 |
| `entry/src/main/ets/utils/StorageUtil.ets` | Preferences持久化单例 |
| `entry/src/main/ets/entryability/EntryAbility.ets` | 应用入口，已集成 `storageUtil.init()` |
| `entry/src/main/resources/base/profile/main_pages.json` | 只有 `"pages/Index"` |

### 不再使用的文件（可删除）
- `entry/src/main/ets/pages/TransactionHall.ets`
- `entry/src/main/ets/pages/MyAssets.ets`
- `entry/src/main/ets/pages/DataDashboard.ets`
- `entry/src/main/ets/pages/ExpenseCalendar.ets`
- `entry/src/main/ets/components/*` (所有组件文件)

---

## 五、已实现功能清单

### Tab 0: 明细大厅
- [x] 搜索栏（按备注/分类名模糊匹配）
- [x] 筛选Chip栏（类型/分类/钱包，横向滚动）
- [x] 按日期分组显示（ListItemGroup + "今天"/"昨天" + 当日收支小计）
- [x] 滑动删除（swipeAction）
- [x] 点击记录弹出编辑DIALOG

### Tab 1: 我的资产
- [x] 净资产渐变卡片（linearGradient 蓝紫渐变）
- [x] 信用卡欠款提示条
- [x] 钱包余额动态计算（初始余额 + 收入 - 支出）
- [x] 钱包卡片（图标/名称/类型/余额/可用额度）
- [x] 添加/编辑钱包DIALOG（名称/类型/余额/信用额度/图标/颜色）
- [x] 钱包滑动删除

### Tab 2: 数据看板
- [x] 收支概览卡片（总支出/总收入）
- [x] 支出分类统计列表
- [x] 预算管理（卡片+进度条+超支警告+添加/编辑DIALOG）
- [x] 订阅管理（卡片+到期天数+过期提示+添加/编辑DIALOG）

### Tab 3: 支出日历
- [x] 月份切换（◀ ▶）
- [x] 月度总支出卡片
- [x] 7列日历Grid（星期标题+日期格子+当日支出额）
- [x] 点击日期显示当日交易明细
- [x] 设置入口（齿轮图标→Settings DIALOG）

### 通用
- [x] 中心圆形"+"按钮添加新记录
- [x] DIALOG弹窗完整表单（类型Radio+金额+分类网格+钱包选择+备注+保存）
- [x] 添加+编辑双模式
- [x] 数据持久化（Preferences + @Watch自动保存）
- [x] 设置DIALOG（货币/语言/版本/清除数据）

---

## 六、待实现功能 (按优先级)

### 高优先级
- [x] 预算spent动态计算（按分类+日期范围筛选支出交易汇总，缓存到budgetSpentCache）
- [x] 钱包余额动态计算优化（缓存到walletBalanceCache，computeWalletBalance仅在数据变更时调用）
- [x] 日历Tab饼图分类统计（PieChart组件 + monthCategoryDataCache）
- [x] 日历Tab月度柱状图（MonthlyBarChart Canvas组件 + monthlyBarDataCache）

### 中优先级
- [x] 转账类型支持（EditRecordPage转账模式UI+onSave保存+明细Tab显示+BookTab筛选Chip+computeWalletBalance转账余额计算）
- [x] UI风格切换（4种风格：极简/新拟态/粗野主义/赛博朋克，sXxx()辅助方法替换硬编码颜色，SettingsPage风格选择）
- [x] 中英文切换（I18n.ets完整翻译系统，this.t.xxx替换所有硬编码中文，SettingsPage语言切换）
- [x] 主题色切换（6种主题色，sPrimary/sChipActive/sFABBg使用themeColor，SettingsPage色盘选择）
- [x] 平台筛选（BookTab添加平台筛选Chip，getFilteredTransactions添加平台筛选逻辑）
- [x] 钱包排序（管理模式下上移/下移按钮，moveWalletUp/Down方法）

### 低优先级
- [x] 图片附件（EditRecordPage图片选择+显示，BookTab缩略图，PhotoPickerUtil集成）
- [x] 跨币种转换（转账模式自动汇率换算+汇率提示，convertCurrency集成）
- [x] 到期提醒（EditBudgetPage/EditSubscriptionPage提醒开关+提前天数设置）
- [x] 信用卡账单日/还款日显示和管理（EditWalletPage账单日/还款日设置，AssetTab信用卡卡片显示）
- [x] 搜索优化（支持钱包名+金额搜索匹配）

---

## 七、代码模式参考

### DIALOG弹窗模板
```typescript
@Component
struct SomeDialogPage {
  @Consume('navStack') navStack: NavPathStack
  @Consume('someData') someData: SomeType[]
  @Consume('editId') editId: string

  @State formField: string = ''

  aboutToAppear(): void {
    if (this.editId !== '') {
      // 预填表单
      for (let i = 0; i < this.someData.length; i++) {
        if (this.someData[i].id === this.editId) {
          this.formField = this.someData[i].field
          break
        }
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        Blank().width('100%').layoutWeight(1).onClick(() => { this.navStack.pop() })
        Scroll() {
          Column({ space: 20 }) {
            Text(this.editId !== '' ? '编辑' : '添加')
            // 表单内容...
            Button('保存').onClick(() => { this.onSave() })
          }.padding({ left: 20, right: 20, top: 20 })
        }
        .width('100%').height('85%').backgroundColor(Color.White).borderRadius({ topLeft: 20, topRight: 20 })
      }
      .width('100%').height('100%')
    }
    .mode(NavDestinationMode.DIALOG).hideTitleBar(true).backgroundColor('rgba(0,0,0,0.4)')
  }

  private onSave(): void {
    // 验证 → 编辑模式替换/添加模式追加 → this.someData = newArray → this.navStack.pop()
  }
}
```

### 数据持久化模板
```typescript
// Index中
@Provide('items') @Watch('onItemsChanged') items: Item[] = []

onItemsChanged(): void {
  if (this.dataLoaded) { this.saveItems() }
}

private saveItems(): void {
  const jsonArr: Record<string, Object>[] = []
  for (let i = 0; i < this.items.length; i++) {
    jsonArr.push(this.items[i].toJson())
  }
  storageUtil.saveItems(JSON.stringify(jsonArr)).catch((e: Error) => {
    console.error('[Index] saveItems failed: ' + String(e))
  })
}

private parseItems(json: string): Item[] {
  try {
    const parsed: Object[] = JSON.parse(json) as Object[]  // 不能用any!
    const result: Item[] = []
    for (let i = 0; i < parsed.length; i++) {
      result.push(createItemFromJson(parsed[i] as Record<string, Object>))
    }
    return result
  } catch (e) {
    return []
  }
}
```

---

## 八、构建与运行

- 构建命令: 在 DevEco Studio 中点击 Build > Build Hap(s)/APP(s)
- 运行: 点击 Run 在模拟器中运行
- 常见构建错误:
  - `arkts-no-any-unknown`: JSON.parse返回any，需用 `as Object[]` 类型断言
  - `AlertDialog.show() 已废弃`: 改用 `this.getUIContext().getPromptAction().showToast()`
  - 类型不匹配: 枚举与string比较需用 `as string` 转换
- 签名警告 `hvigor WARN: Will skip sign 'hos_hap'` 可忽略
