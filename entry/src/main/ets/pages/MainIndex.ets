/**
 * MainIndex - 应用主入口
 * 使用 Tabs + BarPosition.End 实现底部导航
 * 包含四个 TabContent：交易大厅、我的资产、数据看板、消费日历
 * Stack 布局包含全局 FAB 悬浮记账按钮
 * 顶部标题栏含风格切换器和设置入口
 */
import { UIStyle, PageBackgroundMap, PrimaryTextColorMap, SecondaryTextColorMap, TabBarBackgroundMap, FABBackgroundMap, FABIconColorMap, RadiusMap, BRUTALISM_BORDER, NEUMORPHISM_SHADOW_DARK, DividerColorMap, SecondaryBackgroundMap, PrimaryColorMap, CardBackgroundMap } from '../constants/UIStyleConst'
import { TransactionHall } from './TransactionHall'
import { MyAssets } from './MyAssets'
import { DataDashboard } from './DataDashboard'
import { ExpenseCalendar } from './ExpenseCalendar'
import { Transaction, createTransactionFromJson } from '../model/Transaction'
import { Wallet, createWalletFromJson } from '../model/Wallet'
import { Platform, DEFAULT_PLATFORMS, createPlatformFromJson } from '../model/Platform'
import { AddTransactionModal } from '../components/AddTransactionModal'
import { SettingsModal } from '../components/SettingsModal'
import { TransactionType, WalletType } from '../constants/CurrencyConst'
import { storageUtil } from '../utils/StorageUtil'
import { Budget, createBudgetFromJson } from '../model/Budget'
import { Subscription, createSubscriptionFromJson } from '../model/Subscription'
import { getCurrentLanguage, getTranslation } from '../constants/I18n'


// 底部导航项定义
class TabItemDef {
  title: string = ''
  iconActive: string = ''
  iconInactive: string = ''

  constructor(title: string, iconActive: string, iconInactive: string) {
    this.title = title
    this.iconActive = iconActive
    this.iconInactive = iconInactive
  }
}

const TAB_ITEMS: TabItemDef[] = [
  new TabItemDef('交易', '📋', '📋'),
  new TabItemDef('资产', '💰', '💰'),
  new TabItemDef('看板', '📊', '📊'),
  new TabItemDef('日历', '📅', '📅')
]

// 风格选项
class StyleOption {
  key: string = ''
  label: string = ''
  icon: string = ''

  constructor(key: string, label: string, icon: string) {
    this.key = key
    this.label = label
    this.icon = icon
  }
}

const STYLE_OPTIONS: StyleOption[] = [
  new StyleOption(UIStyle.Minimalist, '极简', '◻️'),
  new StyleOption(UIStyle.Neumorphism, '新拟态', '🔲'),
  new StyleOption(UIStyle.Brutalism, '粗野主义', '🧱'),
  new StyleOption(UIStyle.Cyberpunk, '赛博朋克', '🌃')
]

@Preview
@Entry
@Component
struct MainIndex {
  // 全局风格（双向绑定，切换时同步到 AppStorage）
  @StorageLink('currentStyle') currentStyle: string = UIStyle.Minimalist

  // 当前 Tab 索引
  @State currentTab: number = 0

  // 全局交易数据
  @State transactions: Transaction[] = []
  // 全局钱包数据
  @State wallets: Wallet[] = []
  // 全局平台数据
  @State platforms: Platform[] = []

  // 编辑中的交易（null 表示新增模式）
  @State editingTransaction: Transaction | null = null

  // 记账弹窗控制器
  addTxDialogController: CustomDialogController = new CustomDialogController({
    builder: AddTransactionModal({
      walletList: this.wallets,
      platformList: this.platforms,
      transactionList: this.transactions,
      onSave: (tx: Transaction) => {
        this.onTransactionSaved(tx)
      }
    }),
    customStyle: true,
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: 0 }
  })

  // 设置弹窗控制器
  settingsDialogController: CustomDialogController = new CustomDialogController({
    builder: SettingsModal(),
    customStyle: true,
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: 0 }
  })

  // ==================== i18n ====================
  private getT() {
    return getTranslation(getCurrentLanguage())
  }

  // ==================== 生命周期 ====================
  aboutToAppear(): void {
    // 确保 AppStorage 中有 currentStyle 初始值（预览模式下 EntryAbility 不会执行）
    AppStorage.setOrCreate('currentStyle', this.currentStyle)
    this.initMockData()
    this.loadDataFromStorage()
  }

  // ==================== build ====================
  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // ---- 主内容区 ----
      Column() {
        // ---- 顶部标题栏 ----
        this.TitleBar()

        // ---- Tabs 区域 ----
        Tabs({ index: this.currentTab, barPosition: BarPosition.End }) {
          TabContent() {
            TransactionHall({
              transactions: this.transactions,
              wallets: this.wallets,
              platforms: this.platforms,
              onEditTransaction: (tx: Transaction) => {
                this.onEditTransaction(tx)
              },
              onDeleteTransaction: (txId: string) => {
                this.onDeleteTransaction(txId)
              }
            })
          }
          .tabBar(this.TabBarItem(0))

          TabContent() {
            MyAssets({
              wallets: this.wallets,
              transactions: this.transactions,
              onAddWallet: (wallet: Wallet) => {
                this.onWalletAdded(wallet)
              },
              onDeleteWallet: (walletId: string) => {
                this.onWalletDeleted(walletId)
              },
              onEditWallet: (wallet: Wallet) => {
                this.onWalletEdited(wallet)
              },
              onReorderWallets: (wallets: Wallet[]) => {
                this.onWalletsReordered(wallets)
              }
            })
          }
          .tabBar(this.TabBarItem(1))

          TabContent() {
            DataDashboard({ transactions: this.transactions })
          }
          .tabBar(this.TabBarItem(2))

          TabContent() {
            ExpenseCalendar({ transactions: this.transactions, wallets: this.wallets, platforms: this.platforms })
          }
          .tabBar(this.TabBarItem(3))
        }
        .barHeight(56)
        .barBackgroundColor(TabBarBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
        .scrollable(false)
        .onChange((index: number) => {
          this.currentTab = index
        })
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#F5F5F7')

      // ---- FAB 悬浮记账按钮 ----
      this.FAB()
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 顶部标题栏 ====================
  @Builder
  TitleBar() {
    Row() {
      // 风格切换按钮
      Row() {
        Text(this.getCurrentStyleIcon())
          .fontSize(18)
          .margin({ right: 4 })

        Text(this.getCurrentStyleLabel())
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(RadiusMap.get(this.currentStyle) ?? 16)
      .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
      .border({ width: 1, color: DividerColorMap.get(this.currentStyle) ?? '#E5E5E5', style: BorderStyle.Solid })
      .onClick(() => {
        this.settingsDialogController.open()
      })

      Blank()

      // 应用标题
      Text('UniTally')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

      Blank()

      // 设置按钮
      Text('⚙️')
        .fontSize(22)
        .padding(8)
        .onClick(() => {
          this.settingsDialogController.open()
        })
    }
    .width('100%')
    .padding({ left: 16, right: 8, top: 12, bottom: 4 })
  }

  // ==================== FAB 悬浮记账按钮 ====================
  @Builder
  FAB() {
    Column() {
      Text('+')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(FABIconColorMap.get(this.currentStyle) ?? '#FFFFFF')
    }
    .width(56)
    .height(56)
    .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 28)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(FABBackgroundMap.get(this.currentStyle) ?? '#3B82F6')
    .border(this.currentStyle === UIStyle.Brutalism
      ? { width: 3, color: BRUTALISM_BORDER, style: BorderStyle.Solid }
      : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
    .shadow(
      this.currentStyle === UIStyle.Minimalist
        ? { radius: 12, color: '#403B82F6', offsetX: 0, offsetY: 4 }
        : this.currentStyle === UIStyle.Neumorphism
          ? { radius: 8, color: NEUMORPHISM_SHADOW_DARK, offsetX: 6, offsetY: 6 }
          : this.currentStyle === UIStyle.Brutalism
            ? { radius: 0, color: '#0D0D0D', offsetX: 4, offsetY: 4 }
            : { radius: 15, color: '#60CC00FF', offsetX: 0, offsetY: 0 }
    )
    .margin({ right: 20, bottom: 76 })
    .onClick(() => {
      // 新增模式：清除编辑状态
      AppStorage.setOrCreate('editTransactionId', '')
      AppStorage.setOrCreate('editTransactionJson', '')
      this.addTxDialogController.open()
    })
  }

  // ==================== 自定义底部 TabBar ====================
  @Builder
  TabBarItem(index: number) {
    Column() {
      Text(TAB_ITEMS[index].iconActive)
        .fontSize(22)
        .opacity(this.currentTab === index ? 1.0 : 0.5)

      Text(this.getTabTitle(index))
        .fontSize(10)
        .fontColor(this.currentTab === index
          ? (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
          : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'))
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
        .margin({ top: 2 })

      if (this.currentTab === index) {
        Row()
          .width(16)
          .height(3)
          .borderRadius(2)
          .backgroundColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
          .margin({ top: 2 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  // ==================== 交易/钱包回调 ====================

  private onTransactionSaved(tx: Transaction): void {
    // 判断是否为编辑模式：检查 tx.id 是否已存在于列表中
    let isEdit = false
    for (let i = 0; i < this.transactions.length; i++) {
      if (this.transactions[i].id === tx.id) {
        isEdit = true
        break
      }
    }

    if (isEdit) {
      // 编辑模式：替换已有交易
      const newList: Transaction[] = []
      for (let i = 0; i < this.transactions.length; i++) {
        if (this.transactions[i].id === tx.id) {
          newList.push(tx)
        } else {
          newList.push(this.transactions[i])
        }
      }
      this.transactions = newList
      this.editingTransaction = null
      this.saveDataToStorage()
      try {
        this.getUIContext().getPromptAction().showToast({ message: this.getT().transactionSaved })
      } catch (e) {
        console.error('showToast failed:', e)
      }
      return
    }

    // 新增模式
    const newList: Transaction[] = [tx]
    for (let i = 0; i < this.transactions.length; i++) {
      newList.push(this.transactions[i])
    }
    this.transactions = newList
    this.saveDataToStorage()
    try {
      this.getUIContext().getPromptAction().showToast({ message: this.getT().transactionAdded })
    } catch (e) {
      console.error('showToast failed:', e)
    }
  }

  private onEditTransaction(tx: Transaction): void {
    // 通过 AppStorage 传递编辑交易数据给弹窗
    AppStorage.setOrCreate('editTransactionId', tx.id)
    AppStorage.setOrCreate('editTransactionJson', JSON.stringify(tx.toJson()))
    this.addTxDialogController.open()
  }

  private onDeleteTransaction(txId: string): void {
    const newList: Transaction[] = []
    for (let i = 0; i < this.transactions.length; i++) {
      if (this.transactions[i].id !== txId) {
        newList.push(this.transactions[i])
      }
    }
    this.transactions = newList
    this.saveDataToStorage()
    try {
      this.getUIContext().getPromptAction().showToast({ message: this.getT().transactionDeleted })
    } catch (e) {
      console.error('showToast failed:', e)
    }
  }

  private onWalletAdded(wallet: Wallet): void {
    this.wallets.push(wallet)
    this.saveDataToStorage()
    try {
      this.getUIContext().getPromptAction().showToast({ message: this.getT().walletCreated })
    } catch (e) {
      console.error('showToast failed:', e)
    }
  }

  private onWalletDeleted(walletId: string): void {
    const newList: Wallet[] = []
    for (let i = 0; i < this.wallets.length; i++) {
      if (this.wallets[i].id !== walletId) {
        newList.push(this.wallets[i])
      }
    }
    this.wallets = newList
    this.saveDataToStorage()
    try {
      this.getUIContext().getPromptAction().showToast({ message: this.getT().walletDeleted })
    } catch (e) {
      console.error('showToast failed:', e)
    }
  }

  private onWalletEdited(wallet: Wallet): void {
    const newList: Wallet[] = []
    for (let i = 0; i < this.wallets.length; i++) {
      if (this.wallets[i].id === wallet.id) {
        newList.push(wallet)
      } else {
        newList.push(this.wallets[i])
      }
    }
    this.wallets = newList
    this.saveDataToStorage()
    try {
      this.getUIContext().getPromptAction().showToast({ message: this.getT().walletUpdated })
    } catch (e) {
      console.error('showToast failed:', e)
    }
  }

  private onWalletsReordered(wallets: Wallet[]): void {
    this.wallets = wallets
    this.saveDataToStorage()
  }

  // ==================== 辅助方法 ====================

  private getCurrentStyleIcon(): string {
    for (let i = 0; i < STYLE_OPTIONS.length; i++) {
      if (STYLE_OPTIONS[i].key === this.currentStyle) {
        return STYLE_OPTIONS[i].icon
      }
    }
    return '◻️'
  }

  private getCurrentStyleLabel(): string {
    if (this.currentStyle === UIStyle.Minimalist) return this.getT().minimalist
    if (this.currentStyle === UIStyle.Neumorphism) return this.getT().neumorphism
    if (this.currentStyle === UIStyle.Brutalism) return this.getT().brutalism
    if (this.currentStyle === UIStyle.Cyberpunk) return this.getT().cyberpunk
    return this.getT().minimalist
  }

  private getTabTitle(index: number): string {
    if (index === 0) return this.getT().tabTransactionHall
    if (index === 1) return this.getT().tabMyAssets
    if (index === 2) return this.getT().tabBudgetCenter
    if (index === 3) return this.getT().tabExpenseCalendar
    return ''
  }

  /**
   * 初始化模拟数据
   */
  private initMockData(): void {
    this.wallets = [
      new Wallet('w1', '现金', '#E53935', '💰', 'CNY', 5280, WalletType.Cash, 0),
      new Wallet('w2', '储蓄卡', '#43A047', '🏦', 'CNY', 25000, WalletType.Savings, 1),
      new Wallet('w3', '信用卡', '#1E88E5', '💳', 'CNY', -1200, WalletType.Credit, 2),
      new Wallet('w4', 'PayPal', '#F4511E', '📱', 'USD', 800, WalletType.EWallet, 3)
    ]
    this.wallets[2].creditLimit = 30000
    this.wallets[2].billingDay = 5
    this.wallets[2].dueDay = 25

    this.platforms = DEFAULT_PLATFORMS

    const now = Date.now()
    this.transactions = [
      new Transaction('t1', TransactionType.Expense, 35, 'CNY', '', 'w1', 'cat_food',
        new Date(now - 86400000 * 0).toISOString(), '午餐', now - 3600000),
      new Transaction('t2', TransactionType.Expense, 128, 'CNY', '', 'w2', 'cat_shopping',
        new Date(now - 86400000 * 1).toISOString(), '日用品', now - 86400000),
      new Transaction('t3', TransactionType.Income, 15000, 'CNY', '', 'w2', 'cat_salary',
        new Date(now - 86400000 * 2).toISOString(), '月薪', now - 86400000 * 2),
      new Transaction('t4', TransactionType.Transfer, 2000, 'CNY', '', 'w1', '',
        new Date(now - 86400000 * 3).toISOString(), '现金转储蓄', now - 86400000 * 3),
      new Transaction('t5', TransactionType.Expense, 45, 'CNY', '', 'w1', 'cat_transport',
        new Date(now - 86400000 * 3).toISOString(), '打车', now - 86400000 * 3),
      new Transaction('t6', TransactionType.Expense, 15.5, 'USD', '', 'w4', 'cat_food',
        new Date(now - 86400000 * 4).toISOString(), 'Coffee', now - 86400000 * 4),
      new Transaction('t7', TransactionType.Expense, 299, 'CNY', '', 'w3', 'cat_entertainment',
        new Date(now - 86400000 * 5).toISOString(), '视频会员年费', now - 86400000 * 5),
      new Transaction('t8', TransactionType.Income, 500, 'CNY', '', 'w1', 'cat_bonus',
        new Date(now - 86400000 * 6).toISOString(), '项目奖金', now - 86400000 * 6),
      new Transaction('t9', TransactionType.Transfer, 500, 'CNY', '', 'w2', '',
        new Date(now - 86400000 * 7).toISOString(), '储蓄转现金', now - 86400000 * 7)
    ]
    this.transactions[3].fromWalletId = 'w1'
    this.transactions[3].toWalletId = 'w2'
    this.transactions[3].fromAmount = 2000
    this.transactions[3].toAmount = 2000
    this.transactions[3].fromCurrency = 'CNY'
    this.transactions[3].toCurrency = 'CNY'

    this.transactions[8].fromWalletId = 'w2'
    this.transactions[8].toWalletId = 'w1'
    this.transactions[8].fromAmount = 500
    this.transactions[8].toAmount = 500
    this.transactions[8].fromCurrency = 'CNY'
    this.transactions[8].toCurrency = 'CNY'

    // 为部分交易添加平台标记
    this.transactions[0].platformId = 'plat_alipay'
    this.transactions[1].platformId = 'plat_taobao'
    this.transactions[6].platformId = 'plat_jd'
  }

  /**
   * 从持久化存储加载数据
   * 如果存储中有数据则覆盖 mock 数据，否则保留 mock 数据
   */
  private async loadDataFromStorage(): Promise<void> {
    try {
      // 加载交易
      const txJson = await storageUtil.getTransactionsJson()
      if (txJson !== '') {
        const parsed = JSON.parse(txJson) as Record<string, Object>
        const txList: Transaction[] = []
        if (parsed instanceof Array) {
          const parsedArray = parsed as Object[]
          for (let i = 0; i < parsedArray.length; i++) {
            txList.push(createTransactionFromJson(parsedArray[i] as Record<string, Object>))
          }
        }
        this.transactions = txList
      }

      // 加载钱包
      const walletJson = await storageUtil.getWalletsJson()
      if (walletJson !== '') {
        const parsed = JSON.parse(walletJson) as Record<string, Object>
        const walletList: Wallet[] = []
        if (parsed instanceof Array) {
          const parsedArray = parsed as Object[]
          for (let i = 0; i < parsedArray.length; i++) {
            walletList.push(createWalletFromJson(parsedArray[i] as Record<string, Object>))
          }
        }
        this.wallets = walletList
      }

      // 加载预算
      const budgetJson = await storageUtil.getBudgetsJson()
      if (budgetJson !== '') {
        const parsed = JSON.parse(budgetJson) as Record<string, Object>
        const budgetList: Budget[] = []
        if (parsed instanceof Array) {
          const parsedArray = parsed as Object[]
          for (let i = 0; i < parsedArray.length; i++) {
            budgetList.push(createBudgetFromJson(parsedArray[i] as Record<string, Object>))
          }
        }
      }

      // 加载订阅
      const subJson = await storageUtil.getSubscriptionsJson()
      if (subJson !== '') {
        const parsed = JSON.parse(subJson) as Record<string, Object>
        const subList: Subscription[] = []
        if (parsed instanceof Array) {
          const parsedArray = parsed as Object[]
          for (let i = 0; i < parsedArray.length; i++) {
            subList.push(createSubscriptionFromJson(parsedArray[i] as Record<string, Object>))
          }
        }
      }

      // 加载平台
      const platJson = await storageUtil.getPlatformsJson()
      if (platJson !== '') {
        const parsed = JSON.parse(platJson) as Record<string, Object>
        const platList: Platform[] = []
        if (parsed instanceof Array) {
          const parsedArray = parsed as Object[]
          for (let i = 0; i < parsedArray.length; i++) {
            platList.push(createPlatformFromJson(parsedArray[i] as Record<string, Object>))
          }
        }
        this.platforms = platList
      }
    } catch (err) {
      console.error(`[MainIndex] loadDataFromStorage failed: ${String(err)}`)
    }
  }

  /**
   * 保存当前数据到持久化存储
   */
  private saveDataToStorage(): void {
    // 序列化交易
    const txList: Record<string, Object>[] = []
    for (let i = 0; i < this.transactions.length; i++) {
      txList.push(this.transactions[i].toJson())
    }
    storageUtil.saveTransactions(JSON.stringify(txList))

    // 序列化钱包
    const walletList: Record<string, Object>[] = []
    for (let i = 0; i < this.wallets.length; i++) {
      walletList.push(this.wallets[i].toJson())
    }
    storageUtil.saveWallets(JSON.stringify(walletList))

    // 序列化平台
    const platList: Record<string, Object>[] = []
    for (let i = 0; i < this.platforms.length; i++) {
      platList.push(this.platforms[i].toJson())
    }
    storageUtil.savePlatforms(JSON.stringify(platList))
  }
}

export { MainIndex }