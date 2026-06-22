/**
 * UniTally 主页面
 * Navigation + 自定义底栏(中心圆形+按钮) + DIALOG弹窗编辑
 * - 4个Tab：明细 / 资产 / 看板 / 设置
 * - 中心圆形"+"按钮 → 弹出DIALOG添加记录
 * - 点击记录 → 弹出DIALOG编辑记录
 * - 不使用 CustomDialogController / bindSheet / 条件渲染覆盖层
 */
import { Transaction, createTransactionFromJson } from '../model/Transaction'
import { Wallet, createWalletFromJson } from '../model/Wallet'
import { Category, getDefaultExpenseCategories, getDefaultIncomeCategories } from '../model/Category'
import { Platform, getDefaultPlatforms } from '../model/Platform'
import { Budget, createBudgetFromJson } from '../model/Budget'
import { Subscription, createSubscriptionFromJson } from '../model/Subscription'
import { TransactionType, WalletType, getCurrencySymbol, convertCurrency } from '../constants/CurrencyConst'
import { storageUtil } from '../utils/StorageUtil'
import { photoPickerUtil } from '../utils/PhotoPickerUtil'
import { PieChart, PieChartData } from '../components/PieChart'
import {
  UIStyle,
  PageBackgroundMap, PrimaryTextColorMap, SecondaryTextColorMap,
  CardBackgroundMap, CardBorderMap, RadiusMap, PrimaryColorMap,
  IncomeColorMap, ExpenseColorMap, SecondaryBackgroundMap,
  TabBarBackgroundMap, FABBackgroundMap, FABIconColorMap,
  ChipActiveMap, ChipInactiveMap, PrimaryForegroundMap,
  PrimaryBgMap, OverlayMap, DangerBgMap, PrimaryFgMutedMap
} from '../constants/UIStyleConst'
import { Language, getCurrentLanguage, setCurrentLanguage, getTranslation, TranslationSet } from '../constants/I18n'
import { StyleHelper } from '../utils/StyleHelper'

@Entry
@Component
struct Index {
  @Provide('navStack') navStack: NavPathStack = new NavPathStack()
  @Provide('transactions') @Watch('onTransactionsChanged') transactions: Transaction[] = []
  @Provide('wallets') @Watch('onWalletsChanged') wallets: Wallet[] = [] 
  @Provide('editTxId') editTxId: string = ''
  @State currentIndex: number = 0
  @State dataLoaded: boolean = false
  @State fabScale: number = 1.0
  // 明细Tab筛选状态
  @State searchKeyword: string = ''
  @State filterType: string = ''        // '' | 'expense' | 'income' | 'transfer'
  @State filterCategoryId: string = ''  // '' = 全部
  @State filterWalletId: string = ''    // '' = 全部
  @State filterPlatformId: string = ''  // '' = 全部
  // 默认平台/分类列表（响应语言切换）
  @State defaultPlatforms: Platform[] = getDefaultPlatforms()
  @State defaultExpenseCategories: Category[] = getDefaultExpenseCategories()
  @State defaultIncomeCategories: Category[] = getDefaultIncomeCategories()
  @State walletManageMode: boolean = false
  // 日历Tab状态
  @State @Watch('onCalendarMonthChanged') calendarYear: number = new Date().getFullYear()
  @State @Watch('onCalendarMonthChanged') calendarMonth: number = new Date().getMonth() + 1
  @State selectedDate: string = ''
  @Provide('editWalletId') editWalletId: string = ''
  @Provide('budgets') @Watch('onBudgetsChanged') budgets: Budget[] = []
  @Provide('subscriptions') @Watch('onSubscriptionsChanged') subscriptions: Subscription[] = []
  @Provide('editBudgetId') editBudgetId: string = ''
  @Provide('editSubId') editSubId: string = ''
  // 钱包余额缓存：walletId -> 动态余额
  @State walletBalanceCache: Map<string, number> = new Map()
  // 预算已花费缓存：budgetId -> spent
  @State budgetSpentCache: Map<string, number> = new Map()
  // 日历Tab月度缓存（月份切换或交易变更时重建）
  @State monthExpenseTotal: number = 0
  @State monthCategoryDataCache: PieChartData[] = []
  @State monthlyBarDataCache: BarChartDataItem[] = []
  @State calendarCellsCache: CalendarCell[] = []
  // UI风格
  @Provide('currentUIStyle') @Watch('onUIStyleChanged') currentUIStyle: string = UIStyle.Minimalist
  // 语言
  @Provide('currentLang') @Watch('onLangChanged') currentLang: Language = 'zh'
  private t: TranslationSet = getTranslation('zh')
  // 主题色
  @Provide('themeColor') @Watch('onThemeColorChanged') themeColor: string = '#3B82F6'

  aboutToAppear(): void {
    setTimeout(() => { this.loadData() }, 100)
  }

  // 数据变更时自动持久化（仅数据加载完成后）
  onTransactionsChanged(): void {
    if (this.dataLoaded) {
      this.saveTransactions()
      this.rebuildAllCaches()
    }
  }

  onWalletsChanged(): void {
    if (this.dataLoaded) { this.saveWallets() }
  }

  onBudgetsChanged(): void {
    if (this.dataLoaded) {
      this.saveBudgets()
      this.rebuildBudgetSpentCache()
    }
  }

  onSubscriptionsChanged(): void {
    if (this.dataLoaded) { this.saveSubscriptions() }
  }

  onCalendarMonthChanged(): void {
    if (this.dataLoaded) {
      this.rebuildMonthlyCaches()
    }
  }

  onUIStyleChanged(): void {
    if (this.dataLoaded) {
      storageUtil.setCurrentStyle(this.currentUIStyle)
    }
  }

  onLangChanged(): void {
    this.t = getTranslation(this.currentLang)
    AppStorage.setOrCreate<string>('language', this.currentLang)
    // 刷新默认平台/分类列表，使名称跟随语言更新
    this.defaultPlatforms = getDefaultPlatforms()
    this.defaultExpenseCategories = getDefaultExpenseCategories()
    this.defaultIncomeCategories = getDefaultIncomeCategories()
    if (this.dataLoaded) {
      storageUtil.setLanguage(this.currentLang)
    }
  }

  onThemeColorChanged(): void {
    if (this.dataLoaded) {
      storageUtil.setCurrentThemeColor(this.themeColor)
    }
  }

  // ==================== UI风格辅助方法 ====================

  private sPageBg(): string { return PageBackgroundMap.get(this.currentUIStyle) ?? '#FFFFFF' }
  private sFg(): string { return PrimaryTextColorMap.get(this.currentUIStyle) ?? '#1A1A1A' }
  private sFgMuted(): string { return SecondaryTextColorMap.get(this.currentUIStyle) ?? StyleHelper.sFgMuted(this.currentUIStyle) }
  private sCardBg(): string { return CardBackgroundMap.get(this.currentUIStyle) ?? '#FFFFFF' }
  private sCardBorder(): string { return CardBorderMap.get(this.currentUIStyle) ?? '#E5E5E5' }
  private sRadius(): number { return RadiusMap.get(this.currentUIStyle) ?? 8 }
  private sPrimary(): string { return this.themeColor }
  private sPrimaryFg(): string { return PrimaryForegroundMap.get(this.currentUIStyle) ?? '#FFFFFF' }
  private sIncome(): string { return IncomeColorMap.get(this.currentUIStyle) ?? '#22C55E' }
  private sExpense(): string { return ExpenseColorMap.get(this.currentUIStyle) ?? '#EF4444' }
  private sSecondaryBg(): string { return SecondaryBackgroundMap.get(this.currentUIStyle) ?? '#F5F5F5' }
  private sTabBarBg(): string { return TabBarBackgroundMap.get(this.currentUIStyle) ?? '#FFFFFF' }
  private sFABBg(): string { return this.themeColor }
  private sFABIcon(): string { return FABIconColorMap.get(this.currentUIStyle) ?? '#FFFFFF' }
  private sChipActive(): string { return this.themeColor }
  private sChipInactive(): string { return ChipInactiveMap.get(this.currentUIStyle) ?? '#F5F5F5' }
  private sPrimaryBg(): string { return PrimaryBgMap.get(this.currentUIStyle) ?? StyleHelper.sPrimaryBg(this.currentUIStyle) }
  private sOverlay(): string { return OverlayMap.get(this.currentUIStyle) ?? 'rgba(0,0,0,0.4)' }
  private sDangerBg(): string { return DangerBgMap.get(this.currentUIStyle) ?? StyleHelper.sDangerBg(this.currentUIStyle) }
  private sPrimaryFgMuted(): string { return PrimaryFgMutedMap.get(this.currentUIStyle) ?? 'rgba(255,255,255,0.8)' }
  private sIsBrutalism(): boolean { return this.currentUIStyle === UIStyle.Brutalism }
  private sIsNeumorphism(): boolean { return this.currentUIStyle === UIStyle.Neumorphism }
  private sIsCyberpunk(): boolean { return this.currentUIStyle === UIStyle.Cyberpunk }

  // 卡片阴影辅助
  private sCardShadow(): ShadowOptions {
    const cfg = StyleHelper.sCardShadow(this.currentUIStyle)
    return { radius: cfg.radius, color: cfg.color, offsetX: cfg.offsetX, offsetY: cfg.offsetY }
  }
  private sCardShadowLight(): ShadowOptions {
    const cfg = StyleHelper.sCardShadowLight(this.currentUIStyle)
    return { radius: cfg.radius, color: cfg.color, offsetX: cfg.offsetX, offsetY: cfg.offsetY }
  }
  // 卡片边框辅助
  private sBorderWidth(): number { return StyleHelper.sBorderWidth(this.currentUIStyle) }
  private sBorderColor(): string { return StyleHelper.sBorderColor(this.currentUIStyle) }
  private sGlowBorderColor(): string { return StyleHelper.sGlowBorderColor(this.currentUIStyle) }
  private sGradientEnd(): string { return StyleHelper.sGradientEnd(this.currentUIStyle) }

  // ==================== 数据持久化 ====================

  private async loadData(): Promise<void> {
    try {
      const txJson = await storageUtil.getTransactionsJson()
      const walletJson = await storageUtil.getWalletsJson()
      const budgetJson = await storageUtil.getBudgetsJson()
      const subJson = await storageUtil.getSubscriptionsJson()

      if (txJson !== '' && walletJson !== '') {
        this.transactions = this.parseTransactions(txJson)
        this.wallets = this.parseWallets(walletJson)
      } else {
        this.initMockData()
      }

      if (budgetJson !== '') {
        this.budgets = this.parseBudgets(budgetJson)
      }
      if (subJson !== '') {
        this.subscriptions = this.parseSubscriptions(subJson)
      }
      // 加载UI风格（从AppStorage读取，StorageUtil.init已同步）
      const savedStyle = AppStorage.get<string>('currentStyle')
      if (savedStyle !== undefined && savedStyle !== null && savedStyle !== '') {
        this.currentUIStyle = savedStyle
      }
      // 加载语言
      this.currentLang = getCurrentLanguage()
      this.t = getTranslation(this.currentLang)
      // 加载主题色
      this.themeColor = await storageUtil.getCurrentThemeColor()
    } catch (e) {
      console.error('[Index] loadData failed: ' + String(e))
      this.initMockData()
    }
    this.dataLoaded = true
    this.rebuildAllCaches()
  }

  private parseTransactions(json: string): Transaction[] {
    try {
      const parsed: Object[] = JSON.parse(json) as Object[]
      const result: Transaction[] = []
      for (let i = 0; i < parsed.length; i++) {
        result.push(createTransactionFromJson(parsed[i] as Record<string, Object>))
      }
      return result
    } catch (e) {
      console.error('[Index] parseTransactions failed: ' + String(e))
      return []
    }
  }

  private parseWallets(json: string): Wallet[] {
    try {
      const parsed: Object[] = JSON.parse(json) as Object[]
      const result: Wallet[] = []
      for (let i = 0; i < parsed.length; i++) {
        result.push(createWalletFromJson(parsed[i] as Record<string, Object>))
      }
      return result
    } catch (e) {
      console.error('[Index] parseWallets failed: ' + String(e))
      return []
    }
  }

  private parseBudgets(json: string): Budget[] {
    try {
      const parsed: Object[] = JSON.parse(json) as Object[]
      const result: Budget[] = []
      for (let i = 0; i < parsed.length; i++) {
        result.push(createBudgetFromJson(parsed[i] as Record<string, Object>))
      }
      return result
    } catch (e) {
      console.error('[Index] parseBudgets failed: ' + String(e))
      return []
    }
  }

  private parseSubscriptions(json: string): Subscription[] {
    try {
      const parsed: Object[] = JSON.parse(json) as Object[]
      const result: Subscription[] = []
      for (let i = 0; i < parsed.length; i++) {
        result.push(createSubscriptionFromJson(parsed[i] as Record<string, Object>))
      }
      return result
    } catch (e) {
      console.error('[Index] parseSubscriptions failed: ' + String(e))
      return []
    }
  }

  private saveTransactions(): void {
    const jsonArr: Record<string, Object>[] = []
    for (let i = 0; i < this.transactions.length; i++) {
      jsonArr.push(this.transactions[i].toJson())
    }
    storageUtil.saveTransactions(JSON.stringify(jsonArr)).catch((e: Error) => {
      console.error('[Index] saveTransactions failed: ' + String(e))
    })
  }

  private saveWallets(): void {
    const jsonArr: Record<string, Object>[] = []
    for (let i = 0; i < this.wallets.length; i++) {
      jsonArr.push(this.wallets[i].toJson())
    }
    storageUtil.saveWallets(JSON.stringify(jsonArr)).catch((e: Error) => {
      console.error('[Index] saveWallets failed: ' + String(e))
    })
  }

  private saveBudgets(): void {
    const jsonArr: Record<string, Object>[] = []
    for (let i = 0; i < this.budgets.length; i++) {
      jsonArr.push(this.budgets[i].toJson())
    }
    storageUtil.saveBudgets(JSON.stringify(jsonArr)).catch((e: Error) => {
      console.error('[Index] saveBudgets failed: ' + String(e))
    })
  }

  private saveSubscriptions(): void {
    const jsonArr: Record<string, Object>[] = []
    for (let i = 0; i < this.subscriptions.length; i++) {
      jsonArr.push(this.subscriptions[i].toJson())
    }
    storageUtil.saveSubscriptions(JSON.stringify(jsonArr)).catch((e: Error) => {
      console.error('[Index] saveSubscriptions failed: ' + String(e))
    })
  }

  build() {
    Navigation(this.navStack) {
      Column() {
        // ==================== 内容区域 ====================
        Stack() {
          if (this.currentIndex === 0) {
            this.BookTab()
          } else if (this.currentIndex === 1) {
            this.AssetTab()
          } else if (this.currentIndex === 2) {
            this.DashboardTab()
          } else {
            this.CalendarTab()
          }
        }
        .width('100%')
        .layoutWeight(1)

        // ==================== 底部导航栏 ====================
        Stack() {
          // Tab栏背景
          Row() {
            this.TabItemBuilder(this.t.tabTransactionHall, 0, 'file-text')
            this.TabItemBuilder(this.t.tabMyAssets, 1, 'wallet')
            Column() { }.width(56)
            this.TabItemBuilder(this.t.tabBudgetCenter, 2, 'bar-chart')
            this.TabItemBuilder(this.t.tabExpenseCalendar, 3, 'calendar')
          }
          .width('100%')
          .height(56)
          .justifyContent(FlexAlign.SpaceEvenly)
          .backgroundColor(this.sTabBarBg())
          .backdropBlur(20)

          // 中心圆形+按钮
          Stack() {
            Button() {
              Text('+')
                .fontSize(30)
                .fontColor(this.sFABIcon())
                .fontWeight(FontWeight.Bold)
            }
            .width(52)
            .height(52)
            .borderRadius(26)
            .backgroundColor(this.sFABBg())
            .shadow(this.sCardShadow())
            .scale({ x: this.fabScale, y: this.fabScale })
            .animation({ duration: 200, curve: Curve.EaseOut })
            .onClick(() => {
              this.fabScale = 0.9
              setTimeout(() => { this.fabScale = 1.0 }, 100)
              this.editTxId = ''
              this.navStack.pushPathByName('EditRecord', '')
            })
          }
          .width(56)
          .height(56)
          .position({ x: '50%', y: 0 })
          .markAnchor({ x: '50%', y: '50%' })
        }
        .width('100%')
        .height(56)
        .clip(false)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.sPageBg())
    }
    .mode(NavigationMode.Stack)
    .title('')
    .titleMode(NavigationTitleMode.Mini)
    .hideTitleBar(true)
    .navDestination(this.PageMap)
    .width('100%')
    .height('100%')
  }

  // ==================== 路由映射 ====================
  @Builder
  PageMap(name: string) {
    if (name === 'EditRecord') {
      EditRecordPage()
    } else if (name === 'EditWallet') {
      EditWalletPage()
    } else if (name === 'EditBudget') {
      EditBudgetPage()
    } else if (name === 'EditSubscription') {
      EditSubscriptionPage()
    } else if (name === 'Settings') {
      SettingsPage()
    }
  }

  // ==================== Tab项 ====================
  @Builder
  TabItemBuilder(title: string, targetIndex: number, iconName: string) {
    Column() {
      if (iconName === 'file-text') {
        SymbolGlyph($r('sys.symbol.doc_text'))
          .fontSize(20)
          .fontColor(this.currentIndex === targetIndex ? [this.sPrimary()] : [this.sFgMuted()])
      } else if (iconName === 'wallet') {
        SymbolGlyph($r('sys.symbol.wallet'))
          .fontSize(20)
          .fontColor(this.currentIndex === targetIndex ? [this.sPrimary()] : [this.sFgMuted()])
      } else if (iconName === 'bar-chart') {
        SymbolGlyph($r('sys.symbol.histogram'))
          .fontSize(20)
          .fontColor(this.currentIndex === targetIndex ? [this.sPrimary()] : [this.sFgMuted()])
      } else if (iconName === 'calendar') {
        SymbolGlyph($r('sys.symbol.calendar'))
          .fontSize(20)
          .fontColor(this.currentIndex === targetIndex ? [this.sPrimary()] : [this.sFgMuted()])
      }
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === targetIndex ? this.sPrimary() : this.sFgMuted())
        .fontWeight(this.currentIndex === targetIndex ? FontWeight.Medium : FontWeight.Normal)
        .margin({ top: 2 })
    }
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.currentIndex = targetIndex })
  }

  // ==================== Tab 0: 明细列表 ====================
  @Builder
  BookTab() {
    Column() {
      // 标题栏
      Row() {
        Text(this.t.tabTransactionHall)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.sFg())
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 8 })

      // 搜索栏
      Row() {
        TextInput({ placeholder: this.t.searchPlaceholder, text: this.searchKeyword })
          .fontSize(14)
          .layoutWeight(1)
          .onChange((value: string) => { this.searchKeyword = value })
          .borderRadius(10)
          .backgroundColor(this.sSecondaryBg())
        if (this.searchKeyword !== '') {
          Text('✕')
            .fontSize(16)
            .fontColor(this.sFgMuted())
            .margin({ left: 8 })
            .onClick(() => { this.searchKeyword = '' })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      // 筛选Chip栏
      Scroll() {
        Row({ space: 8 }) {
          // 类型筛选
          Text(this.t.allRecords)
            .fontSize(12).fontColor(this.filterType === '' && this.filterCategoryId === '' && this.filterWalletId === '' && this.filterPlatformId === '' ? this.sPrimaryFg() : this.sFg())
            .padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(16)
            .backgroundColor(this.filterType === '' && this.filterCategoryId === '' && this.filterWalletId === '' && this.filterPlatformId === '' ? this.sChipActive() : this.sChipInactive())
            .onClick(() => { this.filterType = ''; this.filterCategoryId = ''; this.filterWalletId = ''; this.filterPlatformId = '' })

          Text(this.t.expense)
            .fontSize(12).fontColor(this.filterType === 'expense' ? this.sPrimaryFg() : this.sFg())
            .padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(16)
            .backgroundColor(this.filterType === 'expense' ? this.sChipActive() : this.sChipInactive())
            .onClick(() => { this.filterType = this.filterType === 'expense' ? '' : 'expense'; this.filterCategoryId = '' })

          Text(this.t.income)
            .fontSize(12).fontColor(this.filterType === 'income' ? this.sPrimaryFg() : this.sFg())
            .padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(16)
            .backgroundColor(this.filterType === 'income' ? this.sChipActive() : this.sChipInactive())
            .onClick(() => { this.filterType = this.filterType === 'income' ? '' : 'income'; this.filterCategoryId = '' })

          Text(this.t.transfer)
            .fontSize(12).fontColor(this.filterType === 'transfer' ? this.sPrimaryFg() : this.sFg())
            .padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(16)
            .backgroundColor(this.filterType === 'transfer' ? this.sChipActive() : this.sChipInactive())
            .onClick(() => { this.filterType = this.filterType === 'transfer' ? '' : 'transfer'; this.filterCategoryId = '' })

          // 分类筛选
          ForEach(this.getUsedCategories(), (cat: Category) => {
            Text(cat.name)
              .fontSize(12).fontColor(this.filterCategoryId === cat.id ? this.sPrimaryFg() : this.sFg())
              .padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(16)
              .backgroundColor(this.filterCategoryId === cat.id ? this.sChipActive() : this.sChipInactive())
              .onClick(() => { this.filterCategoryId = this.filterCategoryId === cat.id ? '' : cat.id; this.filterType = '' })
          }, (cat: Category) => cat.id)

          // 钱包筛选
          ForEach(this.wallets, (wallet: Wallet) => {
            Text(wallet.name)
              .fontSize(12).fontColor(this.filterWalletId === wallet.id ? this.sPrimaryFg() : this.sFg())
              .padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(16)
              .backgroundColor(this.filterWalletId === wallet.id ? this.sChipActive() : this.sChipInactive())
              .onClick(() => { this.filterWalletId = this.filterWalletId === wallet.id ? '' : wallet.id })
          }, (wallet: Wallet) => wallet.id)

          // 平台筛选
          ForEach(this.defaultPlatforms, (plat: Platform) => {
            Text(plat.name)
              .fontSize(12).fontColor(this.filterPlatformId === plat.id ? this.sPrimaryFg() : this.sFg())
              .padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(16)
              .backgroundColor(this.filterPlatformId === plat.id ? this.sChipActive() : this.sChipInactive())
              .onClick(() => { this.filterPlatformId = this.filterPlatformId === plat.id ? '' : plat.id })
          }, (plat: Platform) => plat.id)
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')

      // 交易列表
      if (this.getFilteredTransactions().length === 0) {
        Column() {
          Text(this.t.noRecords)
            .fontSize(14)
            .fontColor(this.sFgMuted())
            .margin({ top: 80 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 0 }) {
          ForEach(this.getDateGroups(), (group: DateGroup) => {
            ListItemGroup({ header: this.DateGroupHeader(group) }) {
              ForEach(group.items, (tx: Transaction) => {
                ListItem() {
                  Row() {
                    Column() {
                      Text(this.getCategoryIcon(tx))
                        .fontSize(20)
                    }
                    .width(40)
                    .height(40)
                    .borderRadius(this.sRadius())
                    .backgroundColor(this.getCategoryBgColor(tx))
                    .justifyContent(FlexAlign.Center)
                    .margin({ right: 12 })

                    Column() {
                      Text(this.getCategoryName(tx))
                        .fontSize(14)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.sFg())
                      if (tx.note && tx.note !== '') {
                        Text(tx.note)
                          .fontSize(12)
                          .fontColor(this.sFgMuted())
                          .margin({ top: 2 })
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    // 图片缩略图
                    if (tx.hasImage && tx.imageUri !== '') {
                      Image(tx.imageUri)
                        .width(36).height(36).borderRadius(6)
                        .objectFit(ImageFit.Cover)
                        .margin({ right: 8 })
                    }

                    Text(this.formatAmount(tx))
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.getAmountColor(tx))
                  }
                  .width('100%')
                  .padding(14)
                  .backgroundColor(this.sCardBg())
                  .shadow(this.sCardShadow())
                  .shadow(this.sCardShadowLight())
                  .border({ width: this.sBorderWidth(), color: this.sBorderColor(), style: BorderStyle.Solid })
                  .borderRadius(this.sRadius())
                  .animation({ duration: 150, curve: Curve.EaseOut })
                  .onClick(() => {
                    this.editTxId = tx.id
                    this.navStack.pushPathByName('EditRecord', '')
                  })
                }
                .swipeAction({ end: this.DeleteSwipeAction(tx) })
              }, (tx: Transaction) => tx.id)
            }
          }, (group: DateGroup) => group.dateKey)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 明细Tab辅助Builder ====================

  @Builder
  DateGroupHeader(group: DateGroup) {
    Row() {
      Text(group.label)
        .fontSize(13)
        .fontColor(this.sFgMuted())
        .fontWeight(FontWeight.Medium)
      Blank()
      if (group.expenseTotal > 0) {
        Text('-¥' + group.expenseTotal.toFixed(2))
          .fontSize(12)
          .fontColor(this.sExpense())
          .margin({ right: 8 })
      }
      if (group.incomeTotal > 0) {
        Text('+¥' + group.incomeTotal.toFixed(2))
          .fontSize(12)
          .fontColor(this.sIncome())
      }
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 12, bottom: 4 })
  }

  @Builder
  DeleteSwipeAction(tx: Transaction) {
    Button() {
      Text(this.t.deleteLabel)
        .fontSize(14)
        .fontColor(this.sPrimaryFg())
    }
    .width(70)
    .height('100%')
    .backgroundColor(this.sExpense())
    .borderRadius(this.sRadius())
    .onClick(() => {
      const newTx: Transaction[] = []
      for (let i = 0; i < this.transactions.length; i++) {
        if (this.transactions[i].id !== tx.id) {
          newTx.push(this.transactions[i])
        }
      }
      this.transactions = newTx
    })
  }

  // ==================== Tab 1: 我的资产 ====================
  @Builder
  AssetTab() {
    Column() {
      // 标题栏
      Row() {
        Text(this.t.myAssets)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.sFg())
          .layoutWeight(1)
        Text(this.walletManageMode ? this.t.done : this.t.manage)
          .fontSize(14)
          .fontColor(this.sPrimary())
          .fontWeight(FontWeight.Medium)
          .margin({ right: 16 })
          .onClick(() => { this.walletManageMode = !this.walletManageMode })
        Text('+ ' + this.t.add)
          .fontSize(14)
          .fontColor(this.sPrimary())
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.editWalletId = ''
            this.navStack.pushPathByName('EditWallet', '')
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 8 })

      // 净资产渐变卡片
      Column() {
        Text(this.t.netWorth)
          .fontSize(14)
          .fontColor(this.sPrimaryFgMuted())
        Text('¥' + this.getNetWorth().toFixed(2))
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.sPrimaryFg())
          .margin({ top: 8 })
        Row() {
          Text(`${this.wallets.length} ${this.t.walletCount}`)
            .fontSize(12)
            .fontColor(this.sPrimaryFgMuted())
        }
        .margin({ top: 8 })
      }
      .width('100%')
      .padding(24)
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [[this.themeColor, 0.0], [this.sGradientEnd(), 1.0]]
      })
      .borderRadius(this.sRadius())
      .margin({ left: 16, right: 16, top: 8, bottom: 16 })
      .alignItems(HorizontalAlign.Start)

      // 信用卡欠款提示
      if (this.getCreditDebt() > 0) {
        Row() {
          Text(this.t.creditCardDebt)
            .fontSize(13)
            .fontColor(this.sFgMuted())
            .layoutWeight(1)
          Text('-¥' + this.getCreditDebt().toFixed(2))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.sExpense())
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .backgroundColor(StyleHelper.sDangerBg(this.currentUIStyle))
        .borderRadius(12)
        .margin({ left: 16, right: 16, bottom: 12 })
      }

      // 钱包列表
      List({ space: 8 }) {
        ForEach(this.wallets, (wallet: Wallet) => {
          ListItem() {
            Row() {
              Column() {
                Text(wallet.icon)
                  .fontSize(24)
              }
              .width(44)
              .height(44)
              .borderRadius(16)
              .backgroundColor(wallet.color + '1A')
              .justifyContent(FlexAlign.Center)
              .margin({ right: 12 })

              Column() {
                Text(wallet.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.sFg())
                Text(this.getWalletTypeLabel(wallet.type) + ' · ' + getCurrencySymbol(wallet.currency))
                  .fontSize(12)
                  .fontColor(this.sFgMuted())
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Column() {
                Text(this.formatWalletBalance(wallet))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.getWalletBalance(wallet) >= 0 ? this.sIncome() : this.sExpense())
                if (wallet.type === WalletType.Credit) {
                  Text(this.t.availableCredit + ' ¥' + wallet.getDisplayBalance().toFixed(2))
                    .fontSize(11)
                    .fontColor(this.sFgMuted())
                    .margin({ top: 2 })
                  if (wallet.billingDay > 0 || wallet.dueDay > 0) {
                    Text(this.t.billingDay + ' ' + wallet.billingDay + this.t.days + '  ' + this.t.dueDay + ' ' + wallet.dueDay + this.t.days)
                      .fontSize(10)
                      .fontColor(this.sFgMuted())
                      .margin({ top: 2 })
                  }
                }
              }
              .alignItems(HorizontalAlign.End)

              // 管理模式：上移/下移按钮
              if (this.walletManageMode) {
                Column({ space: 4 }) {
                  Text('▲')
                    .fontSize(14)
                    .fontColor(this.sPrimary())
                    .onClick(() => { this.moveWalletUp(wallet.id) })
                  Text('▼')
                    .fontSize(14)
                    .fontColor(this.sPrimary())
                    .onClick(() => { this.moveWalletDown(wallet.id) })
                }
                .margin({ left: 8 })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.sCardBg())
            .shadow(this.sCardShadow())
            .shadow(this.sCardShadowLight())
            .border({ width: this.sBorderWidth(), color: this.sBorderColor(), style: BorderStyle.Solid })
            .borderRadius(this.sRadius())
            .onClick(() => {
              this.editWalletId = wallet.id
              this.navStack.pushPathByName('EditWallet', '')
            })
          }
          .swipeAction({ end: this.DeleteWalletSwipeAction(wallet) })
        }, (wallet: Wallet) => wallet.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DeleteWalletSwipeAction(wallet: Wallet) {
    Button() {
      Text(this.t.deleteLabel)
        .fontSize(14)
        .fontColor(this.sPrimaryFg())
    }
    .width(70)
    .height('100%')
    .backgroundColor(this.sExpense())
    .borderRadius(this.sRadius())
    .onClick(() => {
      const newWallets: Wallet[] = []
      for (let i = 0; i < this.wallets.length; i++) {
        if (this.wallets[i].id !== wallet.id) {
          newWallets.push(this.wallets[i])
        }
      }
      this.wallets = newWallets
    })
  }

  // ==================== Tab 2: 看板 ====================
  @Builder
  DashboardTab() {
    Scroll() {
      Column() {
        // 标题栏
        Text(this.t.tabBudgetCenter)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.sFg())
          .width('100%')
          .padding({ left: 20, top: 16, bottom: 16 })

        // 收支概览
        Row() {
          Column() {
            Text(this.t.totalExpense)
              .fontSize(12)
              .fontColor(this.sFgMuted())
            Text('¥' + this.getTotalExpense().toFixed(2))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.sExpense())
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .padding(16)
          .backgroundColor(this.sCardBg())
          .shadow(this.sCardShadow())
          .shadow(this.sCardShadowLight())
          .border({ width: this.sBorderWidth(), color: this.sBorderColor(), style: BorderStyle.Solid })
          .borderRadius(this.sRadius())
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(this.t.totalIncome)
              .fontSize(12)
              .fontColor(this.sFgMuted())
            Text('¥' + this.getTotalIncome().toFixed(2))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.sIncome())
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .padding(16)
          .backgroundColor(this.sCardBg())
          .shadow(this.sCardShadow())
          .shadow(this.sCardShadowLight())
          .border({ width: this.sBorderWidth(), color: this.sBorderColor(), style: BorderStyle.Solid })
          .borderRadius(this.sRadius())
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .justifyContent(FlexAlign.SpaceBetween)

        // 分类统计
        Text(this.t.expenseCategory)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.sFg())
          .width('100%')
          .padding({ left: 20, top: 24, bottom: 8 })

        List({ space: 8 }) {
          ForEach(this.getCategorySummary(), (item: CategorySummaryItem) => {
            ListItem() {
              Row() {
                Text(item.icon)
                  .fontSize(20)
                  .margin({ right: 12 })
                Text(item.name)
                  .fontSize(14)
                  .fontColor(this.sFg())
                  .layoutWeight(1)
                Text('¥' + item.total.toFixed(2))
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.sExpense())
              }
              .width('100%')
              .padding(14)
              .backgroundColor(this.sCardBg())
              .shadow(this.sCardShadow())
              .shadow(this.sCardShadowLight())
              .border({ width: this.sBorderWidth(), color: this.sBorderColor(), style: BorderStyle.Solid })
              .borderRadius(this.sRadius())
            }
          }, (item: CategorySummaryItem) => item.id)
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        // ==================== 预算管理 ====================
        Row() {
          Text(this.t.budgetManagement)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.sFg())
            .layoutWeight(1)
          Text('+ ' + this.t.add)
            .fontSize(14)
            .fontColor(this.sPrimary())
            .onClick(() => {
              this.editBudgetId = ''
              this.navStack.pushPathByName('EditBudget', '')
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 24, bottom: 8 })

        if (this.budgets.length === 0) {
          Text(this.t.noBudgets)
            .fontSize(13)
            .fontColor(this.sFgMuted())
            .padding({ left: 20, bottom: 8 })
        } else {
          List({ space: 8 }) {
            ForEach(this.budgets, (budget: Budget) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(budget.name)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.sFg())
                      .layoutWeight(1)
                    if (this.getCachedBudgetSpent(budget) > budget.amount) {
                      Text(this.t.overBudget)
                        .fontSize(11)
                        .fontColor(this.sPrimaryFg())
                        .backgroundColor(this.sExpense())
                        .borderRadius(8)
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    }
                  }
                  // 进度条
                  Progress({ value: this.getCachedBudgetSpent(budget), total: Math.max(budget.amount, 1) })
                    .width('100%')
                    .height(6)
                    .color(this.getCachedBudgetSpent(budget) > budget.amount ? this.sExpense() : this.sPrimary())
                    .backgroundColor(StyleHelper.sSecondaryBg(this.currentUIStyle))
                    .margin({ top: 8 })
                  Row() {
                    Text(this.t.spent + ' ¥' + this.getCachedBudgetSpent(budget).toFixed(2))
                      .fontSize(12)
                      .fontColor(this.sFgMuted())
                    Text(this.t.budgetAmount + ' ¥' + budget.amount.toFixed(2))
                      .fontSize(12)
                      .fontColor(this.sFgMuted())
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                  .margin({ top: 4 })
                }
                .width('100%')
                .padding(14)
                .backgroundColor(this.sCardBg())
                .shadow(this.sCardShadow())
                .shadow(this.sCardShadowLight())
                .border({ width: this.sBorderWidth(), color: this.sBorderColor(), style: BorderStyle.Solid })
                .borderRadius(this.sRadius())
                .onClick(() => {
                  this.editBudgetId = budget.id
                  this.navStack.pushPathByName('EditBudget', '')
                })
              }
            }, (budget: Budget) => budget.id)
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        }

        // ==================== 订阅管理 ====================
        Row() {
          Text(this.t.subscriptionManagement)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.sFg())
            .layoutWeight(1)
          Text('+ ' + this.t.add)
            .fontSize(14)
            .fontColor(this.sPrimary())
            .onClick(() => {
              this.editSubId = ''
              this.navStack.pushPathByName('EditSubscription', '')
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 24, bottom: 8 })

        if (this.subscriptions.length === 0) {
          Text(this.t.noSubscriptions)
            .fontSize(13)
            .fontColor(this.sFgMuted())
            .padding({ left: 20, bottom: 20 })
        } else {
          List({ space: 8 }) {
            ForEach(this.subscriptions, (sub: Subscription) => {
              ListItem() {
                Row() {
                  Text(sub.icon)
                    .fontSize(24)
                    .margin({ right: 12 })
                  Column() {
                    Text(sub.name)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.sFg())
                    Text(sub.provider)
                      .fontSize(12)
                      .fontColor(this.sFgMuted())
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Column() {
                    Text('¥' + sub.amount.toFixed(2) + '/' + this.getPeriodLabel(sub))
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(sub.isExpired() ? this.sFgMuted() : this.sFg())
                    if (!sub.isExpired()) {
                      Text(sub.getDaysRemaining() + this.t.daysUntilExpiry)
                        .fontSize(11)
                        .fontColor(this.sFgMuted())
                        .margin({ top: 2 })
                    } else {
                      Text(this.t.expired)
                        .fontSize(11)
                        .fontColor(this.sExpense())
                        .margin({ top: 2 })
                    }
                  }
                  .alignItems(HorizontalAlign.End)
                }
                .width('100%')
                .padding(14)
                .backgroundColor(this.sCardBg())
                .shadow(this.sCardShadow())
                .shadow(this.sCardShadowLight())
                .border({ width: this.sBorderWidth(), color: this.sBorderColor(), style: BorderStyle.Solid })
                .borderRadius(this.sRadius())
                .onClick(() => {
                  this.editSubId = sub.id
                  this.navStack.pushPathByName('EditSubscription', '')
                })
              }
            }, (sub: Subscription) => sub.id)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 20 })
        }
      }
    }
    .width('100%')
    .height('100%')
  }

  private getPeriodLabel(sub: Subscription): string {
    // 简单返回周期标签
    return this.t.period1m
  }

  // ==================== Tab 3: 支出日历 ====================
  @Builder
  CalendarTab() {
    Scroll() {
    Column() {
      // 标题栏
      Row() {
        Text(this.t.expenseCalendar)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.sFg())
          .layoutWeight(1)
        // 设置按钮
        Text('⚙️')
          .fontSize(22)
          .onClick(() => {
            this.navStack.pushPathByName('Settings', '')
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 8 })

      // 月份切换
      Row() {
        Text('◀')
          .fontSize(18)
          .fontColor(this.sPrimary())
          .padding(8)
          .onClick(() => { this.prevMonth() })
        Text(`${this.calendarYear}${this.t.yearSuffix}${this.calendarMonth}${this.t.monthSuffix}`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.sFg())
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('▶')
          .fontSize(18)
          .fontColor(this.sPrimary())
          .padding(8)
          .onClick(() => { this.nextMonth() })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      // 月度总支出
      Column() {
        Text(this.t.monthTotalExpense)
          .fontSize(12)
          .fontColor(this.sFgMuted())
        Text('¥' + this.monthExpenseTotal.toFixed(2))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.sExpense())
          .margin({ top: 4 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.sCardBg())
      .shadow(this.sCardShadow())
      .shadow(this.sCardShadowLight())
      .border({ width: this.sBorderWidth(), color: this.sBorderColor(), style: BorderStyle.Solid })
      .borderRadius(this.sRadius())
      .margin({ left: 16, right: 16, bottom: 8 })
      .alignItems(HorizontalAlign.Center)

      // 日历网格
      Column() {
        // 星期标题
        Row() {
          ForEach(this.t.weekdays, (day: string) => {
            Text(day)
              .fontSize(12)
              .fontColor(this.sFgMuted())
              .width('14.28%')
              .textAlign(TextAlign.Center)
              .padding({ top: 4, bottom: 4 })
          }, (day: string, index: number) => `${day}_${index}`)

        }
        .width('100%')

        // 日期格子
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.calendarCellsCache, (cell: CalendarCell) => {
            Column() {
              Text(cell.day > 0 ? String(cell.day) : '')
                .fontSize(14)
                .fontColor(cell.isToday ? this.sPrimary() : (cell.isSelected ? this.sPrimaryFg() : this.sFg()))
                .fontWeight(cell.isToday ? FontWeight.Bold : FontWeight.Normal)
              if (cell.expense > 0) {
                Text(this.currentLang === 'zh'
                  ? (cell.expense >= 10000 ? (cell.expense / 10000).toFixed(1) + this.t.tenThousand : cell.expense >= 1000 ? (cell.expense / 1000).toFixed(1) + 'k' : cell.expense.toFixed(0))
                  : (cell.expense >= 1000 ? (cell.expense / 1000).toFixed(1) + 'k' : cell.expense.toFixed(0)))
                  .fontSize(9)
                  .fontColor(cell.isSelected ? this.sPrimaryFgMuted() : this.sExpense())
                  .margin({ top: 1 })
              }
            }
            .width('14.28%')
            .height(48)
            .justifyContent(FlexAlign.Center)
            .borderRadius(8)
            .backgroundColor(cell.isSelected ? this.sPrimary() : (cell.isToday ? StyleHelper.sPrimaryBg(this.currentUIStyle) : Color.Transparent))
            .onClick(() => {
              if (cell.day > 0) {
                this.selectedDate = this.getCellDateKey(cell.day)
                this.calendarCellsCache = this.computeCalendarCells()
              }
            })
          }, (cell: CalendarCell, index: number) => `${cell.day}_${index}`)
        }
        .width('100%')
      }
      .width('100%')
      .padding(12)
      .backgroundColor(this.sCardBg())
      .shadow(this.sCardShadow())
      .shadow(this.sCardShadowLight())
      .border({ width: this.sBorderWidth(), color: this.sBorderColor(), style: BorderStyle.Solid })
      .borderRadius(this.sRadius())
      .margin({ left: 16, right: 16, bottom: 8 })

      // 月度分类饼图
      Column() {
        Text(this.t.expenseCategories)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.sFg())
          .width('100%')
          .margin({ bottom: 12 })

        if (this.monthCategoryDataCache.length > 0) {
          Row() {
            PieChart({
              data: this.monthCategoryDataCache,
              innerRadius: 45,
              outerRadius: 75,
              centerValue: '¥' + this.monthExpenseTotal.toFixed(0),
              centerLabel: this.t.monthTotalExpense,
              chartWidth: 170,
              chartHeight: 170,
              paddingAngle: 2
            })

            // 图例
            Column({ space: 6 }) {
              ForEach(this.monthCategoryDataCache, (item: PieChartData) => {
                Row({ space: 6 }) {
                  Row().width(10).height(10).borderRadius(5).backgroundColor(item.color)
                  Text(item.label)
                    .fontSize(11).fontColor(StyleHelper.sFgMuted(this.currentUIStyle)).layoutWeight(1)
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text('¥' + item.value.toFixed(0))
                    .fontSize(11).fontWeight(FontWeight.Medium).fontColor(StyleHelper.sFg(this.currentUIStyle))
                }.width('100%')
              }, (item: PieChartData, index: number) => `${item.label}_${index}`)
            }
            .layoutWeight(1)
            .padding({ left: 8 })
          }
          .width('100%')
        } else {
          Text(this.t.noExpense)
            .fontSize(13).fontColor(this.sFgMuted())
            .width('100%').textAlign(TextAlign.Center).padding({ top: 16, bottom: 16 })
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.sCardBg())
      .shadow(this.sCardShadow())
      .shadow(this.sCardShadowLight())
      .border({ width: this.sBorderWidth(), color: this.sBorderColor(), style: BorderStyle.Solid })
      .borderRadius(this.sRadius())
      .margin({ left: 16, right: 16, bottom: 8 })

      // 月度每日柱状图
      Column() {
        Text(this.t.monthlyStats)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.sFg())
          .width('100%')
          .margin({ bottom: 8 })

        MonthlyBarChart({
          data: this.monthlyBarDataCache,
          chartWidth: 340,
          chartHeight: 140
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.sCardBg())
      .shadow(this.sCardShadow())
      .shadow(this.sCardShadowLight())
      .border({ width: this.sBorderWidth(), color: this.sBorderColor(), style: BorderStyle.Solid })
      .borderRadius(this.sRadius())
      .margin({ left: 16, right: 16, bottom: 8 })

      // 选中日期的交易列表
      if (this.selectedDate !== '') {
        Text(this.selectedDate + ' ' + this.t.expense)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.sFg())
          .width('100%')
          .padding({ left: 20, top: 8, bottom: 4 })

        List({ space: 6 }) {
          ForEach(this.getSelectedDayTransactions(), (tx: Transaction) => {
            ListItem() {
              Row() {
                Text(this.getCategoryIcon(tx))
                  .fontSize(18)
                  .margin({ right: 8 })
                Text(this.getCategoryName(tx))
                  .fontSize(13)
                  .fontColor(this.sFg())
                  .layoutWeight(1)
                Text(this.formatAmount(tx))
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.getAmountColor(tx))
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor(this.sCardBg())
              .shadow(this.sCardShadow())
              .shadow(this.sCardShadowLight())
              .border({ width: this.sBorderWidth(), color: this.sBorderColor(), style: BorderStyle.Solid })
              .borderRadius(this.sRadius())
            }
          }, (tx: Transaction) => tx.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }
    }
    .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
  }

  // ==================== 日历Tab辅助方法 ====================

  private prevMonth(): void {
    if (this.calendarMonth === 1) {
      this.calendarMonth = 12
      this.calendarYear--
    } else {
      this.calendarMonth--
    }
    this.selectedDate = ''
  }

  private nextMonth(): void {
    if (this.calendarMonth === 12) {
      this.calendarMonth = 1
      this.calendarYear++
    } else {
      this.calendarMonth++
    }
    this.selectedDate = ''
  }

  /** 计算月度总支出（仅缓存计算时调用） */
  private computeMonthExpense(): number {
    let total = 0
    const monthPrefix = `${this.calendarYear}-${String(this.calendarMonth).padStart(2, '0')}`
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type === TransactionType.Expense && this.getDateStr(tx.datetime).indexOf(monthPrefix) === 0) {
        total += tx.amount
      }
    }
    return total
  }

  /** 计算日历格子数据（仅缓存计算时调用） */
  private computeCalendarCells(): CalendarCell[] {
    const cells: CalendarCell[] = []
    const firstDay = new Date(this.calendarYear, this.calendarMonth - 1, 1)
    const startWeekday = firstDay.getDay() // 0=周日
    const daysInMonth = new Date(this.calendarYear, this.calendarMonth, 0).getDate()
    const todayStr = this.getDateStr(Date.now())

    // 前置空白
    for (let i = 0; i < startWeekday; i++) {
      cells.push({ day: 0, expense: 0, isToday: false, isSelected: false })
    }

    // 日期格子
    for (let d = 1; d <= daysInMonth; d++) {
      const dateKey = this.getCellDateKey(d)
      let expense = 0
      for (let i = 0; i < this.transactions.length; i++) {
        const tx = this.transactions[i]
        if (tx.type === TransactionType.Expense && this.getDateStr(tx.datetime) === dateKey) {
          expense += tx.amount
        }
      }
      cells.push({
        day: d,
        expense: expense,
        isToday: dateKey === todayStr,
        isSelected: dateKey === this.selectedDate
      })
    }

    return cells
  }

  private getCellDateKey(day: number): string {
    return `${this.calendarYear}-${String(this.calendarMonth).padStart(2, '0')}-${String(day).padStart(2, '0')}`
  }

  private getSelectedDayTransactions(): Transaction[] {
    if (this.selectedDate === '') { return [] }
    const result: Transaction[] = []
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (this.getDateStr(tx.datetime) === this.selectedDate) {
        result.push(tx)
      }
    }
    return result
  }

  /**
   * 计算当前月份分类支出饼图数据（仅缓存计算时调用）
   */
  private computeMonthCategoryData(): PieChartData[] {
    const monthPrefix = `${this.calendarYear}-${String(this.calendarMonth).padStart(2, '0')}`
    const map: Map<string, number> = new Map()
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type !== TransactionType.Expense) { continue }
      if (this.getDateStr(tx.datetime).indexOf(monthPrefix) !== 0) { continue }
      const existing = map.get(tx.category)
      map.set(tx.category, (existing !== undefined && existing !== null ? existing : 0) + tx.amount)
    }
    const result: PieChartData[] = []
    const catIds: string[] = []
    map.forEach((val: number, key: string) => {
      catIds.push(key)
    })
    for (let i = 0; i < catIds.length; i++) {
      const catId = catIds[i]
      const val = map.get(catId)
      if (val === undefined || val === null || val <= 0) { continue }
      let name = this.t.other
      let color = StyleHelper.sFgMuted(this.currentUIStyle)
      const expCats = this.defaultExpenseCategories
      for (let j = 0; j < expCats.length; j++) {
        if (expCats[j].id === catId) {
          name = expCats[j].name
          color = expCats[j].color
          break
        }
      }
      result.push({ value: val, color: color, label: name })
    }
    result.sort((a: PieChartData, b: PieChartData) => b.value - a.value)
    return result
  }

  /**
   * 计算当前月份每日柱状图数据（仅缓存计算时调用）
   */
  private computeMonthlyBarData(): BarChartDataItem[] {
    const daysInMonth = new Date(this.calendarYear, this.calendarMonth, 0).getDate()
    const monthPrefix = `${this.calendarYear}-${String(this.calendarMonth).padStart(2, '0')}`
    // 按日汇总
    const dailyMap: Map<number, number> = new Map()
    for (let d = 1; d <= daysInMonth; d++) {
      dailyMap.set(d, 0)
    }
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type !== TransactionType.Expense) { continue }
      const dateStr = this.getDateStr(tx.datetime)
      if (dateStr.indexOf(monthPrefix) !== 0) { continue }
      const day = parseInt(dateStr.substring(8, 10), 10)
      const existing = dailyMap.get(day)
      dailyMap.set(day, (existing !== undefined && existing !== null ? existing : 0) + tx.amount)
    }
    const result: BarChartDataItem[] = []
    for (let d = 1; d <= daysInMonth; d++) {
      const val = dailyMap.get(d)
      result.push({ day: d, value: val !== undefined && val !== null ? val : 0 })
    }
    return result
  }

  // ==================== 业务方法 ====================

  // ---------- 明细Tab筛选 ----------

  private getFilteredTransactions(): Transaction[] {
    let result = this.transactions
    // 类型筛选
    if (this.filterType !== '') {
      const filtered: Transaction[] = []
      for (let i = 0; i < result.length; i++) {
        const txType = result[i].type as string
        if (txType === this.filterType) { filtered.push(result[i]) }
      }
      result = filtered
    }
    // 分类筛选
    if (this.filterCategoryId !== '') {
      const filtered: Transaction[] = []
      for (let i = 0; i < result.length; i++) {
        if (result[i].category === this.filterCategoryId) { filtered.push(result[i]) }
      }
      result = filtered
    }
    // 钱包筛选
    if (this.filterWalletId !== '') {
      const filtered: Transaction[] = []
      for (let i = 0; i < result.length; i++) {
        if (result[i].walletId === this.filterWalletId) { filtered.push(result[i]) }
      }
      result = filtered
    }
    // 平台筛选
    if (this.filterPlatformId !== '') {
      const filtered: Transaction[] = []
      for (let i = 0; i < result.length; i++) {
        if (result[i].platformId === this.filterPlatformId) { filtered.push(result[i]) }
      }
      result = filtered
    }
    // 搜索
    if (this.searchKeyword !== '') {
      const kw = this.searchKeyword.toLowerCase()
      const filtered: Transaction[] = []
      for (let i = 0; i < result.length; i++) {
        const tx = result[i]
        if (tx.note.toLowerCase().indexOf(kw) >= 0 ||
            this.getCategoryName(tx).toLowerCase().indexOf(kw) >= 0 ||
            this.getWalletNameById(tx.walletId).toLowerCase().indexOf(kw) >= 0 ||
            tx.amount.toString().indexOf(kw) >= 0) {
          filtered.push(tx)
        }
      }
      result = filtered
    }
    return result
  }

  private getDateGroups(): DateGroup[] {
    const filtered = this.getFilteredTransactions()
    const map: Map<string, DateGroup> = new Map()
    const today = this.getDateStr(Date.now())
    const yesterday = this.getDateStr(Date.now() - 86400000)

    for (let i = 0; i < filtered.length; i++) {
      const tx = filtered[i]
      const dateKey = this.getDateStr(tx.datetime)
      let group = map.get(dateKey)
      if (!group) {
        let label = dateKey
        if (dateKey === today) { label = this.t.today }
        else if (dateKey === yesterday) { label = this.t.yesterday }
        group = { dateKey: dateKey, label: label, items: [], expenseTotal: 0, incomeTotal: 0 }
        map.set(dateKey, group)
      }
      group.items.push(tx)
      if (tx.type === TransactionType.Expense) { group.expenseTotal += tx.amount }
      if (tx.type === TransactionType.Income) { group.incomeTotal += tx.amount }
    }

    const result: DateGroup[] = []
    const keys: string[] = []
    map.forEach((val: DateGroup, key: string) => { keys.push(key) })
    keys.sort((a: string, b: string) => b.localeCompare(a)) // 日期倒序
    for (let i = 0; i < keys.length; i++) {
      const val = map.get(keys[i])
      if (val) { result.push(val) }
    }
    return result
  }

  private getDateStr(timestamp: number | string): string {
    const d = new Date(timestamp)
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  private getUsedCategories(): Category[] {
    const usedIds: Map<string, boolean> = new Map()
    for (let i = 0; i < this.transactions.length; i++) {
      usedIds.set(this.transactions[i].category, true)
    }
    const result: Category[] = []
    const allCats = this.defaultExpenseCategories.concat(this.defaultIncomeCategories)
    for (let i = 0; i < allCats.length; i++) {
      if (usedIds.has(allCats[i].id)) { result.push(allCats[i]) }
    }
    return result
  }

  // ---------- 通用方法 ----------

  private getNetWorth(): number {
    let total = 0
    for (let i = 0; i < this.wallets.length; i++) {
      total += this.getWalletBalance(this.wallets[i])
    }
    return total
  }

  private getCreditDebt(): number {
    let debt = 0
    for (let i = 0; i < this.wallets.length; i++) {
      if (this.wallets[i].type === WalletType.Credit && this.wallets[i].balance < 0) {
        debt += Math.abs(this.wallets[i].balance)
      }
    }
    return debt
  }

  private getWalletBalance(wallet: Wallet): number {
    const cached = this.walletBalanceCache.get(wallet.id)
    if (cached !== undefined && cached !== null) {
      return cached
    }
    return this.computeWalletBalance(wallet)
  }

  private computeWalletBalance(wallet: Wallet): number {
    let balance = wallet.balance
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type === TransactionType.Transfer) {
        // 转出钱包减少
        const fromWid = tx.fromWalletId !== '' ? tx.fromWalletId : tx.walletId
        if (fromWid === wallet.id) {
          balance -= (tx.fromAmount > 0 ? tx.fromAmount : tx.amount)
        }
        // 转入钱包增加
        if (tx.toWalletId === wallet.id) {
          balance += (tx.toAmount > 0 ? tx.toAmount : tx.amount)
        }
      } else if (tx.walletId === wallet.id) {
        if (tx.type === TransactionType.Income) { balance += tx.amount }
        else if (tx.type === TransactionType.Expense) { balance -= tx.amount }
      }
    }
    return balance
  }

  private rebuildAllCaches(): void {
    this.rebuildWalletBalanceCache()
    this.rebuildBudgetSpentCache()
    this.rebuildMonthlyCaches()
  }

  private rebuildWalletBalanceCache(): void {
    const newCache: Map<string, number> = new Map()
    for (let i = 0; i < this.wallets.length; i++) {
      newCache.set(this.wallets[i].id, this.computeWalletBalance(this.wallets[i]))
    }
    this.walletBalanceCache = newCache
  }

  private rebuildBudgetSpentCache(): void {
    const newCache: Map<string, number> = new Map()
    for (let i = 0; i < this.budgets.length; i++) {
      newCache.set(this.budgets[i].id, this.computeBudgetSpent(this.budgets[i]))
    }
    this.budgetSpentCache = newCache
  }

  private rebuildMonthlyCaches(): void {
    this.monthExpenseTotal = this.computeMonthExpense()
    this.monthCategoryDataCache = this.computeMonthCategoryData()
    this.monthlyBarDataCache = this.computeMonthlyBarData()
    this.calendarCellsCache = this.computeCalendarCells()
  }

  /**
   * 计算预算已花费金额（仅缓存计算时调用，不在渲染中调用）
   */
  private computeBudgetSpent(budget: Budget): number {
    if (budget.category === '') { return 0 }
    const dateRange = this.getBudgetDateRange(budget)
    let spent = 0
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type !== TransactionType.Expense) { continue }
      if (tx.category !== budget.category) { continue }
      const txDate = this.getDateStr(tx.datetime)
      if (dateRange.start !== '' && txDate < dateRange.start) { continue }
      if (dateRange.end !== '' && txDate > dateRange.end) { continue }
      spent += tx.amount
    }
    return spent
  }

  /** 从缓存读取预算已花费金额（O(1)，渲染中调用） */
  private getCachedBudgetSpent(budget: Budget): number {
    const val = this.budgetSpentCache.get(budget.id)
    return val !== undefined && val !== null ? val : 0
  }

  /**
   * 根据预算周期和创建时间计算日期范围
   */
  private getBudgetDateRange(budget: Budget): DateRange {
    const now = new Date()
    // 如果预算有自定义日期范围，优先使用
    if (budget.startDate !== '' && budget.endDate !== '') {
      return { start: budget.startDate, end: budget.endDate }
    }
    // 根据周期自动计算当前周期范围
    const period = budget.period
    let start = ''
    let end = ''
    if (period === '3d') {
      start = this.getDateStr(Date.now() - 2 * 86400000)
      end = this.getDateStr(Date.now())
    } else if (period === '1w') {
      const dayOfWeek = now.getDay()
      start = this.getDateStr(Date.now() - dayOfWeek * 86400000)
      end = this.getDateStr(Date.now() + (6 - dayOfWeek) * 86400000)
    } else if (period === '1m') {
      start = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`
      const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
      end = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`
    } else if (period === '3m') {
      const quarterStart = Math.floor(now.getMonth() / 3) * 3
      start = `${now.getFullYear()}-${String(quarterStart + 1).padStart(2, '0')}-01`
      const quarterEndMonth = quarterStart + 2
      const lastDay = new Date(now.getFullYear(), quarterEndMonth + 1, 0).getDate()
      end = `${now.getFullYear()}-${String(quarterEndMonth + 1).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`
    } else if (period === '6m') {
      const halfStart = now.getMonth() < 6 ? 0 : 6
      start = `${now.getFullYear()}-${String(halfStart + 1).padStart(2, '0')}-01`
      const halfEndMonth = halfStart + 5
      const lastDay = new Date(now.getFullYear(), halfEndMonth + 1, 0).getDate()
      end = `${now.getFullYear()}-${String(halfEndMonth + 1).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`
    } else if (period === '1y') {
      start = `${now.getFullYear()}-01-01`
      end = `${now.getFullYear()}-12-31`
    }
    return { start: start, end: end }
  }

  private formatWalletBalance(wallet: Wallet): string {
    const balance = this.getWalletBalance(wallet)
    const symbol = getCurrencySymbol(wallet.currency)
    return (balance >= 0 ? '' : '-') + symbol + Math.abs(balance).toFixed(2)
  }

  private getWalletTypeLabel(type: WalletType): string {
    if (type === WalletType.Cash) { return this.t.cash }
    if (type === WalletType.Savings) { return this.t.savings }
    if (type === WalletType.Credit) { return this.t.credit }
    if (type === WalletType.EWallet) { return this.t.ewallet }
    return this.t.other
  }

  private moveWalletUp(walletId: string): void {
    let idx = -1
    for (let i = 0; i < this.wallets.length; i++) {
      if (this.wallets[i].id === walletId) { idx = i; break }
    }
    if (idx > 0) {
      const newWallets = [...this.wallets]
      const temp = newWallets[idx]
      newWallets[idx] = newWallets[idx - 1]
      newWallets[idx - 1] = temp
      this.wallets = newWallets
    }
  }

  private moveWalletDown(walletId: string): void {
    let idx = -1
    for (let i = 0; i < this.wallets.length; i++) {
      if (this.wallets[i].id === walletId) { idx = i; break }
    }
    if (idx >= 0 && idx < this.wallets.length - 1) {
      const newWallets = [...this.wallets]
      const temp = newWallets[idx]
      newWallets[idx] = newWallets[idx + 1]
      newWallets[idx + 1] = temp
      this.wallets = newWallets
    }
  }

  private getWalletNameById(walletId: string): string {
    for (let i = 0; i < this.wallets.length; i++) {
      if (this.wallets[i].id === walletId) { return this.wallets[i].name }
    }
    return this.t.other
  }

  private getCategoryIcon(tx: Transaction): string {
    if (tx.type === TransactionType.Transfer) { return '🔄' }
    const categories = tx.type === TransactionType.Expense ? this.defaultExpenseCategories : this.defaultIncomeCategories
    for (let i = 0; i < categories.length; i++) {
      if (categories[i].id === tx.category) { return categories[i].icon }
    }
    return '📌'
  }

  private getCategoryName(tx: Transaction): string {
    if (tx.type === TransactionType.Transfer) {
      const fromName = this.getWalletNameById(tx.fromWalletId !== '' ? tx.fromWalletId : tx.walletId)
      const toName = this.getWalletNameById(tx.toWalletId)
      return `${fromName} → ${toName}`
    }
    const categories = tx.type === TransactionType.Expense ? this.defaultExpenseCategories : this.defaultIncomeCategories
    for (let i = 0; i < categories.length; i++) {
      if (categories[i].id === tx.category) { return categories[i].name }
    }
    return this.t.other
  }

  private getCategoryBgColor(tx: Transaction): string {
    if (tx.type === TransactionType.Transfer) { return StyleHelper.sPrimaryBg(this.currentUIStyle) }
    const categories = tx.type === TransactionType.Expense ? this.defaultExpenseCategories : this.defaultIncomeCategories
    for (let i = 0; i < categories.length; i++) {
      if (categories[i].id === tx.category) {
        const hex = categories[i].color
        if (hex && hex.length >= 7) {
          const r = parseInt(hex.substring(1, 3), 16)
          const g = parseInt(hex.substring(3, 5), 16)
          const b = parseInt(hex.substring(5, 7), 16)
          return `rgba(${r}, ${g}, ${b}, 0.1)`
        }
      }
    }
    return this.sSecondaryBg()
  }

  private getAmountColor(tx: Transaction): ResourceColor {
    if (tx.type === TransactionType.Expense) { return this.sExpense() }
    if (tx.type === TransactionType.Income) { return this.sIncome() }
    return this.sPrimary()
  }

  private formatAmount(tx: Transaction): string {
    if (tx.type === TransactionType.Transfer) {
      const fromSymbol = getCurrencySymbol(tx.fromCurrency !== '' ? tx.fromCurrency : tx.currency)
      const toSymbol = getCurrencySymbol(tx.toCurrency !== '' ? tx.toCurrency : tx.currency)
      const fromAmt = tx.fromAmount > 0 ? tx.fromAmount : tx.amount
      const toAmt = tx.toAmount > 0 ? tx.toAmount : tx.amount
      return `${fromSymbol}${fromAmt.toFixed(2)} → ${toSymbol}${toAmt.toFixed(2)}`
    }
    const symbol = getCurrencySymbol(tx.currency)
    if (tx.type === TransactionType.Expense) { return `-${symbol}${tx.amount.toFixed(2)}` }
    if (tx.type === TransactionType.Income) { return `+${symbol}${tx.amount.toFixed(2)}` }
    return `${symbol}${tx.amount.toFixed(2)}`
  }

  private getTotalBalance(): number {
    let total = 0
    for (let i = 0; i < this.wallets.length; i++) { total += this.wallets[i].balance }
    return total
  }

  private getTotalExpense(): number {
    let total = 0
    for (let i = 0; i < this.transactions.length; i++) {
      if (this.transactions[i].type === TransactionType.Expense) { total += this.transactions[i].amount }
    }
    return total
  }

  private getTotalIncome(): number {
    let total = 0
    for (let i = 0; i < this.transactions.length; i++) {
      if (this.transactions[i].type === TransactionType.Income) { total += this.transactions[i].amount }
    }
    return total
  }

  private getCategorySummary(): CategorySummaryItem[] {
    const map: Map<string, CategorySummaryItem> = new Map()
    for (let i = 0; i < this.transactions.length; i++) {
      const tx = this.transactions[i]
      if (tx.type !== TransactionType.Expense) { continue }
      const catId = tx.category
      const existing = map.get(catId)
      if (!existing) {
        const categories = this.defaultExpenseCategories
        let icon = '📌'
        let name = this.t.other
        for (let j = 0; j < categories.length; j++) {
          if (categories[j].id === catId) {
            icon = categories[j].icon
            name = categories[j].name
            break
          }
        }
        map.set(catId, { id: catId, icon: icon, name: name, total: 0 })
      }
      const item = map.get(catId)
      if (item) {
        item.total += tx.amount
      }
    }
    const result: CategorySummaryItem[] = []
    const keys: string[] = []
    map.forEach((val: CategorySummaryItem, key: string) => { keys.push(key) })
    for (let i = 0; i < keys.length; i++) {
      const val = map.get(keys[i])
      if (val) { result.push(val) }
    }
    result.sort((a: CategorySummaryItem, b: CategorySummaryItem) => b.total - a.total)
    return result
  }

  // ==================== 数据初始化 ====================
  private initMockData(): void {
    this.wallets = [
      new Wallet('w1', this.t.defaultCash, '#E53935', '💰', 'CNY', 5280, WalletType.Cash, 0),
      new Wallet('w2', this.t.defaultSavings, '#43A047', '🏦', 'CNY', 25000, WalletType.Savings, 1),
      new Wallet('w3', this.t.defaultCredit, '#1E88E5', '💳', 'CNY', -1200, WalletType.Credit, 2),
    ]
    const now = Date.now()
    this.transactions = [
      new Transaction('t1', TransactionType.Expense, 35, 'CNY', '', 'w1', 'cat_food', new Date(now).toISOString(), this.t.defaultLunch, now - 3600000),
      new Transaction('t2', TransactionType.Expense, 128, 'CNY', '', 'w2', 'cat_shopping', new Date(now - 86400000).toISOString(), this.t.defaultDaily, now - 86400000),
      new Transaction('t3', TransactionType.Income, 15000, 'CNY', '', 'w2', 'cat_salary', new Date(now - 86400000 * 2).toISOString(), this.t.defaultSalary, now - 86400000 * 2),
      new Transaction('t4', TransactionType.Expense, 45, 'CNY', '', 'w1', 'cat_transport', new Date(now - 86400000 * 3).toISOString(), this.t.defaultTaxi, now - 86400000 * 3),
    ]
    // 首次初始化后手动保存（此时 dataLoaded 还为 false，@Watch 不会触发）
    this.saveTransactions()
    this.saveWallets()
  }
}

// ==================== 分类统计项 ====================
class CategorySummaryItem {
  id: string = ''
  icon: string = ''
  name: string = ''
  total: number = 0
}

// ==================== 日期分组 ====================
class DateGroup {
  dateKey: string = ''
  label: string = ''
  items: Transaction[] = []
  expenseTotal: number = 0
  incomeTotal: number = 0
}

// ==================== 日历格子 ====================
class CalendarCell {
  day: number = 0
  expense: number = 0
  isToday: boolean = false
  isSelected: boolean = false
}

// ==================== 日期范围 ====================
class DateRange {
  start: string = ''
  end: string = ''
}

// ==================== 柱状图数据项 ====================
class BarChartDataItem {
  day: number = 0
  value: number = 0
}

// ==================== 月度柱状图组件 ====================
@Component
struct MonthlyBarChart {
  @Prop @Watch('onDataChanged') data: BarChartDataItem[] = []
  @Prop chartWidth: number = 340
  @Prop chartHeight: number = 140
  @Consume('currentUIStyle') currentUIStyle: string
  @Consume('themeColor') themeColor: string
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  @State private drawFlag: number = 0

  onDataChanged(): void {
    this.drawFlag++
    // 延迟一帧让Canvas准备好再绘制
    setTimeout(() => { this.drawChart() }, 16)
  }

  build() {
    Scroll() {
      Canvas(this.context)
        .width(Math.max(this.data.length * 12, this.chartWidth))
        .height(this.chartHeight)
        .onReady(() => {
          this.drawChart()
        })
    }
    .width('100%')
    .height(this.chartHeight)
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Auto)
  }

  private drawChart(): void {
    const ctx = this.context
    const w = Math.max(this.data.length * 12, this.chartWidth)
    const h = this.chartHeight
    ctx.clearRect(0, 0, w, h)

    if (this.data.length === 0) { return }

    const padLeft = 8
    const padRight = 8
    const padTop = 16
    const padBottom = 20
    const chartW = w - padLeft - padRight
    const chartH = h - padTop - padBottom

    // 找最大值
    let maxVal = 0
    for (let i = 0; i < this.data.length; i++) {
      if (this.data[i].value > maxVal) { maxVal = this.data[i].value }
    }
    if (maxVal <= 0) { maxVal = 1 }

    const barWidth = chartW / this.data.length * 0.7
    const barGap = chartW / this.data.length * 0.3

    for (let i = 0; i < this.data.length; i++) {
      const item = this.data[i]
      const x = padLeft + i * (barWidth + barGap) + barGap / 2
      const barH = (item.value / maxVal) * chartH
      const y = padTop + chartH - barH

      // 柱体
      ctx.fillStyle = item.value > 0 ? this.themeColor : StyleHelper.sChipInactive(this.currentUIStyle)
      ctx.beginPath()
      const radius = Math.min(3, barWidth / 2)
      // 圆角矩形
      if (barH > radius * 2) {
        ctx.moveTo(x, y + radius)
        ctx.arcTo(x, y, x + radius, y, radius)
        ctx.arcTo(x + barWidth, y, x + barWidth, y + radius, radius)
        ctx.lineTo(x + barWidth, y + barH)
        ctx.lineTo(x, y + barH)
        ctx.closePath()
      } else {
        ctx.rect(x, y, barWidth, barH)
      }
      ctx.fill()

      // 日期标签（每5天显示一次）
      if (item.day === 1 || item.day % 5 === 0 || item.day === this.data.length) {
        ctx.fillStyle = StyleHelper.sFgMuted(this.currentUIStyle)
        ctx.font = '9px sans-serif'
        ctx.textAlign = 'center'
        ctx.fillText(String(item.day), x + barWidth / 2, h - 4)
      }
    }
  }
}

// ==================== DIALOG弹窗编辑页面 ====================
@Component
struct EditRecordPage {
  @Consume('navStack') navStack: NavPathStack
  @Consume('transactions') transactions: Transaction[]
  @Consume('wallets') wallets: Wallet[]
  @Consume('editTxId') editTxId: string
  @Consume('currentLang') currentLang: Language
  @Consume('currentUIStyle') currentUIStyle: string
  @Consume('themeColor') themeColor: string
  private t: TranslationSet = getTranslation('zh')

  @State formType: TransactionType = TransactionType.Expense
  @State formAmount: string = ''
  @State formNote: string = ''
  @State formCategoryId: string = 'cat_food'
  @State formWalletId: string = 'w1'
  // 转账模式字段
  @State formFromWalletId: string = ''
  @State formToWalletId: string = ''
  @State formFromAmount: string = ''
  @State formToAmount: string = ''
  // 图片字段
  @State formImageUri: string = ''
  @State formHasImage: boolean = false

  aboutToAppear(): void {
    this.t = getTranslation(this.currentLang)
    if (this.editTxId !== '') {
      for (let i = 0; i < this.transactions.length; i++) {
        if (this.transactions[i].id === this.editTxId) {
          const tx = this.transactions[i]
          this.formType = tx.type
          this.formAmount = tx.amount.toString()
          this.formNote = tx.note
          this.formCategoryId = tx.category
          this.formWalletId = tx.walletId
          if (tx.type === TransactionType.Transfer) {
            this.formFromWalletId = tx.fromWalletId
            this.formToWalletId = tx.toWalletId
            this.formFromAmount = tx.fromAmount > 0 ? tx.fromAmount.toString() : tx.amount.toString()
            this.formToAmount = tx.toAmount > 0 ? tx.toAmount.toString() : tx.amount.toString()
          }
          // 图片
          this.formImageUri = tx.imageUri
          this.formHasImage = tx.hasImage
          break
        }
      }
    } else {
      // 新建时默认选第一个钱包
      if (this.wallets.length > 0) {
        this.formWalletId = this.wallets[0].id
        this.formFromWalletId = this.wallets[0].id
        this.formToWalletId = this.wallets.length > 1 ? this.wallets[1].id : ''
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 点击空白区域关闭
        Blank()
          .width('100%')
          .layoutWeight(1)
          .onClick(() => { this.navStack.pop() })

        // 表单区域
        Scroll() {
          Column({ space: 20 }) {
            // 标题
            Text(this.editTxId !== '' ? this.t.editTransaction : this.t.addTransaction)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(StyleHelper.sFg(this.currentUIStyle))
              .width('100%')

            // 类型选择
            Row({ space: 16 }) {
              Text(this.t.selectType)
                .fontSize(16)
                .fontColor(StyleHelper.sFg(this.currentUIStyle))
                .width(48)
              Column() {
                Radio({ value: 'expense', group: 'typeGroup' })
                  .checked(this.formType === TransactionType.Expense)
                  .onChange((isChecked: boolean) => {
                    if (isChecked) { this.formType = TransactionType.Expense }
                  })
                Text(this.t.expense)
                  .fontSize(12)
              }
              Column() {
                Radio({ value: 'income', group: 'typeGroup' })
                  .checked(this.formType === TransactionType.Income)
                  .onChange((isChecked: boolean) => {
                    if (isChecked) { this.formType = TransactionType.Income }
                  })
                Text(this.t.income)
                  .fontSize(12)
              }
              Column() {
                Radio({ value: 'transfer', group: 'typeGroup' })
                  .checked(this.formType === TransactionType.Transfer)
                  .onChange((isChecked: boolean) => {
                    if (isChecked) { this.formType = TransactionType.Transfer }
                  })
                Text(this.t.transfer)
                  .fontSize(12)
              }
            }

            // 转账模式：转出钱包 + 转入钱包 + 双金额
            if (this.formType === TransactionType.Transfer) {
              // 转出钱包
              Text(this.t.fromWallet)
                .fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width('100%')
              Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                ForEach(this.wallets, (wallet: Wallet) => {
                  Row() {
                    Text(wallet.icon).fontSize(14).margin({ right: 4 })
                    Text(wallet.name)
                      .fontSize(12)
                      .fontColor(this.formFromWalletId === wallet.id ? StyleHelper.sPrimaryFg(this.currentUIStyle) : StyleHelper.sFg(this.currentUIStyle))
                  }
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .borderRadius(16)
                  .backgroundColor(this.formFromWalletId === wallet.id ? StyleHelper.sPrimary(this.themeColor) : StyleHelper.sChipInactive(this.currentUIStyle))
                  .margin({ right: 6, bottom: 6 })
                  .onClick(() => { this.formFromWalletId = wallet.id })
                }, (wallet: Wallet) => wallet.id)
              }

              // 转入钱包
              Text(this.t.toWallet)
                .fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width('100%')
              Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                ForEach(this.wallets, (wallet: Wallet) => {
                  Row() {
                    Text(wallet.icon).fontSize(14).margin({ right: 4 })
                    Text(wallet.name)
                      .fontSize(12)
                      .fontColor(this.formToWalletId === wallet.id ? StyleHelper.sPrimaryFg(this.currentUIStyle) : StyleHelper.sFg(this.currentUIStyle))
                  }
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .borderRadius(16)
                  .backgroundColor(this.formToWalletId === wallet.id ? StyleHelper.sPrimary(this.themeColor) : StyleHelper.sChipInactive(this.currentUIStyle))
                  .margin({ right: 6, bottom: 6 })
                  .onClick(() => { this.formToWalletId = wallet.id })
                }, (wallet: Wallet) => wallet.id)
              }

              // 转出金额
              Row({ space: 10 }) {
                Text(this.t.fromAmount)
                  .fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width(48)
                TextInput({ placeholder: '0.00', text: this.formFromAmount })
                  .type(InputType.Number)
                  .onChange((value: string) => {
                    this.formFromAmount = value
                    this.autoConvertToAmount()
                  })
                  .layoutWeight(1)
              }

              // 汇率提示
              if (this.formFromAmount !== '' && this.getTransferFromCurrency() !== this.getTransferToCurrency()) {
                Text(this.getExchangeRateHint())
                  .fontSize(11).fontColor(StyleHelper.sFgMuted(this.currentUIStyle)).width('100%')
                  .padding({ left: 58 })
              }

              // 转入金额
              Row({ space: 10 }) {
                Text(this.t.toAmount)
                  .fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width(48)
                TextInput({ placeholder: '0.00', text: this.formToAmount })
                  .type(InputType.Number)
                  .onChange((value: string) => { this.formToAmount = value })
                  .layoutWeight(1)
              }
            } else {
            Row({ space: 10 }) {
              Text(this.t.amount)
                .fontSize(16)
                .fontColor(StyleHelper.sFg(this.currentUIStyle))
                .width(48)
              TextInput({ placeholder: '0.00', text: this.formAmount })
                .type(InputType.Number)
                .onChange((value: string) => { this.formAmount = value })
                .layoutWeight(1)
            }

            // 分类选择
            Text(this.t.selectCategoryLabel)
              .fontSize(16)
              .fontColor(StyleHelper.sFg(this.currentUIStyle))
              .width('100%')

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.getCategoriesForType(), (cat: Category) => {
                Column() {
                  Text(cat.icon)
                    .fontSize(22)
                  Text(cat.name)
                    .fontSize(10)
                    .fontColor(this.formCategoryId === cat.id ? StyleHelper.sPrimary(this.themeColor) : StyleHelper.sFgMuted(this.currentUIStyle))
                    .margin({ top: 2 })
                }
                .width(56)
                .height(56)
                .borderRadius(12)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(this.formCategoryId === cat.id ? StyleHelper.sPrimaryBg(this.currentUIStyle) : StyleHelper.sChipInactive(this.currentUIStyle))
                .border(this.formCategoryId === cat.id
                  ? { width: 2, color: StyleHelper.sPrimary(this.themeColor), style: BorderStyle.Solid }
                  : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
                .margin({ right: 6, bottom: 6 })
                .onClick(() => { this.formCategoryId = cat.id })
              }, (cat: Category) => cat.id)
            }

            // 钱包选择
            Text(this.t.selectWalletLabel)
              .fontSize(16)
              .fontColor(StyleHelper.sFg(this.currentUIStyle))
              .width('100%')

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.wallets, (wallet: Wallet) => {
                Row() {
                  Text(wallet.icon)
                    .fontSize(14)
                    .margin({ right: 4 })
                  Text(wallet.name)
                    .fontSize(12)
                    .fontColor(this.formWalletId === wallet.id ? StyleHelper.sPrimaryFg(this.currentUIStyle) : StyleHelper.sFg(this.currentUIStyle))
                }
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.formWalletId === wallet.id ? StyleHelper.sPrimary(this.themeColor) : StyleHelper.sChipInactive(this.currentUIStyle))
                .margin({ right: 6, bottom: 6 })
                .onClick(() => { this.formWalletId = wallet.id })
              }, (wallet: Wallet) => wallet.id)
            }

            // 备注
            Row({ space: 10 }) {
              Text(this.t.note)
                .fontSize(16)
                .fontColor(StyleHelper.sFg(this.currentUIStyle))
                .width(48)
              TextInput({ placeholder: this.t.addNote, text: this.formNote })
                .onChange((value: string) => { this.formNote = value })
                .layoutWeight(1)
            }

            // 图片附件
            Row({ space: 10 }) {
              Text(this.t.image)
                .fontSize(16)
                .fontColor(StyleHelper.sFg(this.currentUIStyle))
                .width(48)
              if (this.formHasImage && this.formImageUri !== '') {
                Image(this.formImageUri)
                  .width(60).height(60).borderRadius(8)
                  .objectFit(ImageFit.Cover)
                  .onClick(() => { this.formHasImage = false; this.formImageUri = '' })
              } else {
                Row() {
                  Text('+')
                    .fontSize(24).fontColor(StyleHelper.sFgMuted(this.currentUIStyle))
                }
                .width(60).height(60).borderRadius(8)
                .backgroundColor(StyleHelper.sChipInactive(this.currentUIStyle))
                .justifyContent(FlexAlign.Center)
                .onClick(async () => {
                  const uri = await photoPickerUtil.pickSingleImage()
                  if (uri !== '') {
                    this.formImageUri = uri
                    this.formHasImage = true
                  }
                })
              }
            }
            }

            // 保存按钮（转账和支出/收入共用）
            Button(this.editTxId !== '' ? this.t.save : this.t.addTransaction)
              .width('100%')
              .height(44)
              .backgroundColor(StyleHelper.sPrimary(this.themeColor))
              .fontColor(StyleHelper.sPrimaryFg(this.currentUIStyle))
              .fontSize(16)
              .borderRadius(12)
              .margin({ top: 10, bottom: 20 })
              .onClick(() => { this.onSave() })
          }
          .padding({ left: 20, right: 20, top: 20 })
        }
        .width('100%')
        .height('85%')
        .backgroundColor(StyleHelper.sCardBg(this.currentUIStyle))
        .borderRadius({ topLeft: 20, topRight: 20 })
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavDestinationMode.DIALOG)
    .hideTitleBar(true)
    .backgroundColor(StyleHelper.sOverlay(this.currentUIStyle))
  }

  // ==================== 跨币种转账辅助 ====================

  private getTransferFromCurrency(): string {
    for (let i = 0; i < this.wallets.length; i++) {
      if (this.wallets[i].id === this.formFromWalletId) { return this.wallets[i].currency }
    }
    return 'CNY'
  }

  private getTransferToCurrency(): string {
    for (let i = 0; i < this.wallets.length; i++) {
      if (this.wallets[i].id === this.formToWalletId) { return this.wallets[i].currency }
    }
    return 'CNY'
  }

  private autoConvertToAmount(): void {
    const fromAmt = parseFloat(this.formFromAmount)
    if (isNaN(fromAmt) || fromAmt <= 0) { return }
    const fromCur = this.getTransferFromCurrency()
    const toCur = this.getTransferToCurrency()
    if (fromCur === toCur) {
      this.formToAmount = this.formFromAmount
      return
    }
    const converted = convertCurrency(fromAmt, fromCur, toCur)
    this.formToAmount = converted.toFixed(2)
  }

  private getExchangeRateHint(): string {
    const fromCur = this.getTransferFromCurrency()
    const toCur = this.getTransferToCurrency()
    const rate = convertCurrency(1, fromCur, toCur)
    return `1 ${getCurrencySymbol(fromCur)}${fromCur} ≈ ${rate.toFixed(4)} ${getCurrencySymbol(toCur)}${toCur}`
  }

  // ==================== 表单方法 ====================

  private getCategoriesForType(): Category[] {
    return this.formType === TransactionType.Expense ? this.defaultExpenseCategories : this.defaultIncomeCategories
  }

  private onSave(): void {
    if (this.formType === TransactionType.Transfer) {
      // 转账模式校验
      const fromAmount = parseFloat(this.formFromAmount)
      const toAmount = parseFloat(this.formToAmount)
      if (isNaN(fromAmount) || fromAmount <= 0 || isNaN(toAmount) || toAmount <= 0) {
        try {
          this.getUIContext().getPromptAction().showToast({ message: this.t.pleaseEnterAmount })
        } catch (e) {
          console.error('showToast failed:' + String(e))
        }
        return
      }
      if (this.formFromWalletId === '' || this.formToWalletId === '') {
        try {
          this.getUIContext().getPromptAction().showToast({ message: this.t.pleaseSelectWallet })
        } catch (e) {
          console.error('showToast failed:' + String(e))
        }
        return
      }
      if (this.formFromWalletId === this.formToWalletId) {
        try {
          this.getUIContext().getPromptAction().showToast({ message: this.t.needTwoWallets })
        } catch (e) {
          console.error('showToast failed:' + String(e))
        }
        return
      }

      // 获取钱包币种
      let fromCurrency = 'CNY'
      let toCurrency = 'CNY'
      for (let i = 0; i < this.wallets.length; i++) {
        if (this.wallets[i].id === this.formFromWalletId) { fromCurrency = this.wallets[i].currency }
        if (this.wallets[i].id === this.formToWalletId) { toCurrency = this.wallets[i].currency }
      }

      if (this.editTxId !== '') {
        // 编辑转账
        const newTransactions: Transaction[] = []
        for (let i = 0; i < this.transactions.length; i++) {
          if (this.transactions[i].id === this.editTxId) {
            const oldTx = this.transactions[i]
            const tx = new Transaction(
              this.editTxId, TransactionType.Transfer, fromAmount, fromCurrency,
              oldTx.platformId, this.formFromWalletId, '', oldTx.datetime, this.formNote, oldTx.createdAt
            )
            tx.toWalletId = this.formToWalletId
            tx.fromAmount = fromAmount
            tx.toAmount = toAmount
            tx.fromCurrency = fromCurrency
            tx.toCurrency = toCurrency
            tx.imageUri = this.formImageUri
            tx.hasImage = this.formHasImage
            newTransactions.push(tx)
          } else {
            newTransactions.push(this.transactions[i])
          }
        }
        this.transactions = newTransactions
      } else {
        // 新增转账
        const now = Date.now()
        const tx = new Transaction(
          'tx_' + now, TransactionType.Transfer, fromAmount, fromCurrency,
          '', this.formFromWalletId, '', new Date(now).toISOString(), this.formNote, now
        )
        tx.toWalletId = this.formToWalletId
        tx.fromAmount = fromAmount
        tx.toAmount = toAmount
        tx.fromCurrency = fromCurrency
        tx.toCurrency = toCurrency
        tx.imageUri = this.formImageUri
        tx.hasImage = this.formHasImage
        this.transactions = [tx, ...this.transactions]
      }
    } else {
      // 支出/收入模式
      const amount = parseFloat(this.formAmount)
      if (isNaN(amount) || amount <= 0) {
        try {
          this.getUIContext().getPromptAction().showToast({ message: this.t.pleaseEnterAmount })
        } catch (e) {
          console.error('showToast failed:' + String(e))
        }
        return
      }

      if (this.editTxId !== '') {
        const newTransactions: Transaction[] = []
        for (let i = 0; i < this.transactions.length; i++) {
          if (this.transactions[i].id === this.editTxId) {
            const oldTx = this.transactions[i]
            const newTx = new Transaction(
              this.editTxId, this.formType, amount, oldTx.currency,
              oldTx.platformId, this.formWalletId, this.formCategoryId,
              oldTx.datetime, this.formNote, oldTx.createdAt
            )
            newTx.imageUri = this.formImageUri
            newTx.hasImage = this.formHasImage
            newTransactions.push(newTx)
          } else {
            newTransactions.push(this.transactions[i])
          }
        }
        this.transactions = newTransactions
      } else {
        const now = Date.now()
        const tx = new Transaction(
          'tx_' + now, this.formType, amount, 'CNY', '',
          this.formWalletId, this.formCategoryId,
          new Date(now).toISOString(), this.formNote, now
        )
        tx.imageUri = this.formImageUri
        tx.hasImage = this.formHasImage
        this.transactions = [tx, ...this.transactions]
      }
    }

    this.navStack.pop()

    try {
      this.getUIContext().getPromptAction().showToast({ message: this.editTxId !== '' ? this.t.transactionSaved : this.t.transactionAdded })
    } catch (e) {
      console.error('showToast failed:' + String(e))
    }
  }
}

// ==================== DIALOG弹窗编辑钱包 ====================
@Component
struct EditWalletPage {
  @Consume('navStack') navStack: NavPathStack
  @Consume('wallets') wallets: Wallet[]
  @Consume('editWalletId') editWalletId: string
  @Consume('currentLang') currentLang: Language
  @Consume('currentUIStyle') currentUIStyle: string
  @Consume('themeColor') themeColor: string
  private t: TranslationSet = getTranslation('zh')

  @State formName: string = ''
  @State formBalance: string = '0'
  @State formType: WalletType = WalletType.Cash
  @State formIcon: string = '💰'
  @State formColor: string = '#3B82F6'
  @State formCreditLimit: string = '0'
  @State formBillingDay: string = '1'
  @State formDueDay: string = '1'

  private readonly ICONS: string[] = ['💰', '🏦', '💳', '📱', '🏠', '🚗', '✈️', '🎮', '📈', '🎁']
  private readonly COLORS: string[] = ['#E53935', '#43A047', '#1E88E5', '#8E24AA', '#FF7043', '#FDD835', '#00ACC1', '#546E7A', '#3B82F6', '#8B5CF6']

  aboutToAppear(): void {
    this.t = getTranslation(this.currentLang)
    if (this.editWalletId !== '') {
      for (let i = 0; i < this.wallets.length; i++) {
        if (this.wallets[i].id === this.editWalletId) {
          const w = this.wallets[i]
          this.formName = w.name
          this.formBalance = w.balance.toString()
          this.formType = w.type
          this.formIcon = w.icon
          this.formColor = w.color
          if (w.type === WalletType.Credit) {
            this.formCreditLimit = w.creditLimit.toString()
            this.formBillingDay = w.billingDay.toString()
            this.formDueDay = w.dueDay.toString()
          }
          break
        }
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        Blank()
          .width('100%')
          .layoutWeight(1)
          .onClick(() => { this.navStack.pop() })

        Scroll() {
          Column({ space: 20 }) {
            Text(this.editWalletId !== '' ? this.t.edit : this.t.addWallet)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(StyleHelper.sFg(this.currentUIStyle))
              .width('100%')

            // 名称
            Row({ space: 10 }) {
              Text(this.t.walletName)
                .fontSize(16)
                .fontColor(StyleHelper.sFg(this.currentUIStyle))
                .width(56)
              TextInput({ placeholder: this.t.walletName, text: this.formName })
                .onChange((value: string) => { this.formName = value })
                .layoutWeight(1)
            }

            // 类型
            Text(this.t.walletType)
              .fontSize(16)
              .fontColor(StyleHelper.sFg(this.currentUIStyle))
              .width('100%')
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              this.WalletTypeChip(this.t.cash, WalletType.Cash, '💰')
              this.WalletTypeChip(this.t.savings, WalletType.Savings, '🏦')
              this.WalletTypeChip(this.t.credit, WalletType.Credit, '💳')
              this.WalletTypeChip(this.t.ewallet, WalletType.EWallet, '📱')
            }

            // 余额
            Row({ space: 10 }) {
              Text(this.t.balance)
                .fontSize(16)
                .fontColor(StyleHelper.sFg(this.currentUIStyle))
                .width(56)
              TextInput({ placeholder: '0.00', text: this.formBalance })
                .type(InputType.Number)
                .onChange((value: string) => { this.formBalance = value })
                .layoutWeight(1)
            }

            // 信用额度（仅信用卡）
            if (this.formType === WalletType.Credit) {
              Row({ space: 10 }) {
                Text(this.t.creditLimit)
                  .fontSize(16)
                  .fontColor(StyleHelper.sFg(this.currentUIStyle))
                  .width(56)
                TextInput({ placeholder: '0.00', text: this.formCreditLimit })
                  .type(InputType.Number)
                  .onChange((value: string) => { this.formCreditLimit = value })
                  .layoutWeight(1)
              }

              // 账单日
              Row({ space: 10 }) {
                Text(this.t.billingDay)
                  .fontSize(16)
                  .fontColor(StyleHelper.sFg(this.currentUIStyle))
                  .width(56)
                TextInput({ placeholder: '1', text: this.formBillingDay })
                  .type(InputType.Number)
                  .onChange((value: string) => { this.formBillingDay = value })
                  .layoutWeight(1)
                Text(this.t.days)
                  .fontSize(14).fontColor(StyleHelper.sFgMuted(this.currentUIStyle))
              }

              // 还款日
              Row({ space: 10 }) {
                Text(this.t.dueDay)
                  .fontSize(16)
                  .fontColor(StyleHelper.sFg(this.currentUIStyle))
                  .width(56)
                TextInput({ placeholder: '1', text: this.formDueDay })
                  .type(InputType.Number)
                  .onChange((value: string) => { this.formDueDay = value })
                  .layoutWeight(1)
                Text(this.t.days)
                  .fontSize(14).fontColor(StyleHelper.sFgMuted(this.currentUIStyle))
              }
            }

            // 图标选择
            Text(this.t.selectIcon)
              .fontSize(16)
              .fontColor(StyleHelper.sFg(this.currentUIStyle))
              .width('100%')
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.ICONS, (icon: string) => {
                Text(icon)
                  .fontSize(24)
                  .width(44)
                  .height(44)
                  .textAlign(TextAlign.Center)
                  .borderRadius(12)
                  .backgroundColor(this.formIcon === icon ? StyleHelper.sPrimaryBg(this.currentUIStyle) : StyleHelper.sChipInactive(this.currentUIStyle))
                  .border(this.formIcon === icon
                    ? { width: 2, color: StyleHelper.sPrimary(this.themeColor), style: BorderStyle.Solid }
                    : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
                  .margin({ right: 6, bottom: 6 })
                  .onClick(() => { this.formIcon = icon })
              }, (icon: string, index: number) => `${icon}_${index}`)
            }

            // 颜色选择
            Text(this.t.selectColor)
              .fontSize(16)
              .fontColor(StyleHelper.sFg(this.currentUIStyle))
              .width('100%')
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.COLORS, (color: string) => {
                Column() {
                  Column() { }
                    .width(24)
                    .height(24)
                    .borderRadius(12)
                    .backgroundColor(color)
                    .border(this.formColor === color
                      ? { width: 3, color: StyleHelper.sFg(this.currentUIStyle), style: BorderStyle.Solid }
                      : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
                }
                .width(40)
                .height(40)
                .justifyContent(FlexAlign.Center)
                .margin({ right: 4, bottom: 4 })
                .onClick(() => { this.formColor = color })
              }, (color: string, index: number) => `${color}_${index}`)
            }

            // 保存按钮
            Button(this.editWalletId !== '' ? this.t.save : this.t.addWallet)
              .width('100%')
              .height(44)
              .backgroundColor(StyleHelper.sPrimary(this.themeColor))
              .fontColor(StyleHelper.sPrimaryFg(this.currentUIStyle))
              .fontSize(16)
              .borderRadius(12)
              .margin({ top: 10, bottom: 20 })
              .onClick(() => { this.onSave() })
          }
          .padding({ left: 20, right: 20, top: 20 })
        }
        .width('100%')
        .height('85%')
        .backgroundColor(StyleHelper.sCardBg(this.currentUIStyle))
        .borderRadius({ topLeft: 20, topRight: 20 })
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavDestinationMode.DIALOG)
    .hideTitleBar(true)
    .backgroundColor(StyleHelper.sOverlay(this.currentUIStyle))
  }

  @Builder
  WalletTypeChip(label: string, type: WalletType, icon: string) {
    Row() {
      Text(icon)
        .fontSize(14)
        .margin({ right: 4 })
      Text(label)
        .fontSize(12)
        .fontColor(this.formType === type ? StyleHelper.sPrimaryFg(this.currentUIStyle) : StyleHelper.sFg(this.currentUIStyle))
    }
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .borderRadius(16)
    .backgroundColor(this.formType === type ? StyleHelper.sPrimary(this.themeColor) : StyleHelper.sChipInactive(this.currentUIStyle))
    .margin({ right: 6, bottom: 6 })
    .onClick(() => { this.formType = type })
  }

  private onSave(): void {
    if (this.formName === '') {
      try {
        this.getUIContext().getPromptAction().showToast({ message: this.t.pleaseEnterWalletName })
      } catch (e) { console.error('showToast failed:' + String(e)) }
      return
    }

    const balance = parseFloat(this.formBalance)
    const creditLimit = parseFloat(this.formCreditLimit)

    if (this.editWalletId !== '') {
      // 编辑模式
      const newWallets: Wallet[] = []
      for (let i = 0; i < this.wallets.length; i++) {
        if (this.wallets[i].id === this.editWalletId) {
          const w = new Wallet(
            this.editWalletId,
            this.formName,
            this.formColor,
            this.formIcon,
            this.wallets[i].currency,
            isNaN(balance) ? 0 : balance,
            this.formType,
            this.wallets[i].order
          )
          w.creditLimit = isNaN(creditLimit) ? 0 : creditLimit
          if (this.formType === WalletType.Credit) {
            w.billingDay = parseInt(this.formBillingDay) || 1
            w.dueDay = parseInt(this.formDueDay) || 1
          }
          newWallets.push(w)
        } else {
          newWallets.push(this.wallets[i])
        }
      }
      this.wallets = newWallets
    } else {
      // 添加模式
      const wallet = new Wallet(
        'w_' + Date.now(),
        this.formName,
        this.formColor,
        this.formIcon,
        'CNY',
        isNaN(balance) ? 0 : balance,
        this.formType,
        this.wallets.length
      )
      wallet.creditLimit = isNaN(creditLimit) ? 0 : creditLimit
      if (this.formType === WalletType.Credit) {
        wallet.billingDay = parseInt(this.formBillingDay) || 1
        wallet.dueDay = parseInt(this.formDueDay) || 1
      }
      this.wallets = [...this.wallets, wallet]
    }

    this.navStack.pop()

    try {
      this.getUIContext().getPromptAction().showToast({ message: this.editWalletId !== '' ? this.t.transactionSaved : this.t.walletCreated })
    } catch (e) { console.error('showToast failed:' + String(e)) }
  }
}

// ==================== DIALOG弹窗编辑预算 ====================
@Component
struct EditBudgetPage {
  @Consume('navStack') navStack: NavPathStack
  @Consume('budgets') budgets: Budget[]
  @Consume('editBudgetId') editBudgetId: string
  @Consume('currentLang') currentLang: Language
  @Consume('currentUIStyle') currentUIStyle: string
  @Consume('themeColor') themeColor: string
  private t: TranslationSet = getTranslation('zh')

  @State formName: string = ''
  @State formAmount: string = ''
  @State formCategoryId: string = ''
  @State formPeriod: string = '1m'
  @State formNote: string = ''
  @State formNotifyEnabled: boolean = false
  @State formNotifyDaysBefore: string = '3'

  private PERIODS: string[][] = [['3d', ''], ['1w', ''], ['1m', ''], ['3m', ''], ['6m', ''], ['1y', '']]

  aboutToAppear(): void {
    this.t = getTranslation(this.currentLang)
    // Update period labels with translations
    this.PERIODS[0][1] = this.t.period3d
    this.PERIODS[1][1] = this.t.period1w
    this.PERIODS[2][1] = this.t.period1m
    this.PERIODS[3][1] = this.t.period3m
    this.PERIODS[4][1] = this.t.period6m
    this.PERIODS[5][1] = this.t.period1y
    if (this.editBudgetId !== '') {
      for (let i = 0; i < this.budgets.length; i++) {
        if (this.budgets[i].id === this.editBudgetId) {
          const b = this.budgets[i]
          this.formName = b.name
          this.formAmount = b.amount.toString()
          this.formCategoryId = b.category
          this.formPeriod = b.period
          this.formNote = b.note
          this.formNotifyEnabled = b.notifyEnabled
          this.formNotifyDaysBefore = b.notifyDaysBefore.toString()
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
            Text(this.editBudgetId !== '' ? this.t.editBudget : this.t.addBudget)
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor(StyleHelper.sFg(this.currentUIStyle)).width('100%')

            Row({ space: 10 }) {
              Text(this.t.budgetName).fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width(56)
              TextInput({ placeholder: this.t.budgetName, text: this.formName })
                .onChange((value: string) => { this.formName = value }).layoutWeight(1)
            }

            Row({ space: 10 }) {
              Text(this.t.amount).fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width(56)
              TextInput({ placeholder: '0.00', text: this.formAmount })
                .type(InputType.Number)
                .onChange((value: string) => { this.formAmount = value }).layoutWeight(1)
            }

            Text(this.t.selectCategoryLabel).fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width('100%')
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.defaultExpenseCategories, (cat: Category) => {
                Column() {
                  Text(cat.icon).fontSize(20)
                  Text(cat.name).fontSize(10).fontColor(this.formCategoryId === cat.id ? StyleHelper.sPrimary(this.themeColor) : StyleHelper.sFgMuted(this.currentUIStyle)).margin({ top: 2 })
                }
                .width(56).height(56).borderRadius(12).justifyContent(FlexAlign.Center)
                .backgroundColor(this.formCategoryId === cat.id ? StyleHelper.sPrimaryBg(this.currentUIStyle) : StyleHelper.sChipInactive(this.currentUIStyle))
                .border(this.formCategoryId === cat.id ? { width: 2, color: StyleHelper.sPrimary(this.themeColor), style: BorderStyle.Solid } : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
                .margin({ right: 6, bottom: 6 })
                .onClick(() => { this.formCategoryId = cat.id })
              }, (cat: Category) => cat.id)
            }

            Text(this.t.period).fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width('100%')
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.PERIODS, (p: string[]) => {
                Text(p[1])
                  .fontSize(12).fontColor(this.formPeriod === p[0] ? StyleHelper.sPrimaryFg(this.currentUIStyle) : StyleHelper.sFg(this.currentUIStyle))
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(16)
                  .backgroundColor(this.formPeriod === p[0] ? StyleHelper.sPrimary(this.themeColor) : StyleHelper.sChipInactive(this.currentUIStyle))
                  .margin({ right: 6, bottom: 6 })
                  .onClick(() => { this.formPeriod = p[0] })
              }, (p: string[]) => p[0])
            }

            Row({ space: 10 }) {
              Text(this.t.note).fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width(56)
              TextInput({ placeholder: this.t.addNote, text: this.formNote })
                .onChange((value: string) => { this.formNote = value }).layoutWeight(1)
            }

            // 提醒设置
            Row() {
              Text(this.t.notifyEnabled)
                .fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.formNotifyEnabled })
                .onChange((isOn: boolean) => { this.formNotifyEnabled = isOn })
            }.width('100%')

            if (this.formNotifyEnabled) {
              Row({ space: 10 }) {
                Text(this.t.notifyBefore)
                  .fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width(80)
                TextInput({ placeholder: '3', text: this.formNotifyDaysBefore })
                  .type(InputType.Number)
                  .onChange((value: string) => { this.formNotifyDaysBefore = value })
                  .layoutWeight(1)
              }
            }

            Button(this.editBudgetId !== '' ? this.t.save : this.t.addBudget)
              .width('100%').height(44).backgroundColor(StyleHelper.sPrimary(this.themeColor)).fontColor(StyleHelper.sPrimaryFg(this.currentUIStyle))
              .fontSize(16).borderRadius(12).margin({ top: 10, bottom: 20 })
              .onClick(() => { this.onSave() })
          }
          .padding({ left: 20, right: 20, top: 20 })
        }
        .width('100%').height('85%').backgroundColor(StyleHelper.sCardBg(this.currentUIStyle)).borderRadius({ topLeft: 20, topRight: 20 })
      }
      .width('100%').height('100%')
    }
    .mode(NavDestinationMode.DIALOG).hideTitleBar(true).backgroundColor(StyleHelper.sOverlay(this.currentUIStyle))
  }

  private onSave(): void {
    const amount = parseFloat(this.formAmount)
    if (this.formName === '' || isNaN(amount) || amount <= 0) {
      try { this.getUIContext().getPromptAction().showToast({ message: this.t.pleaseEnterBudgetName }) } catch (e) { }
      return
    }

    // spent 由 Index.getBudgetSpent() 动态计算，保存时设为0即可
    const spent = 0
    const notifyEnabled = this.formNotifyEnabled
    const notifyDaysBefore = parseInt(this.formNotifyDaysBefore) || 3

    if (this.editBudgetId !== '') {
      const newBudgets: Budget[] = []
      for (let i = 0; i < this.budgets.length; i++) {
        if (this.budgets[i].id === this.editBudgetId) {
          newBudgets.push(new Budget(this.editBudgetId, this.formName, amount, spent, this.formCategoryId, StyleHelper.sPrimary(this.themeColor), '', '', this.formNote, this.formPeriod, notifyEnabled, notifyDaysBefore, 'CNY', this.budgets[i].createdAt))
        } else {
          newBudgets.push(this.budgets[i])
        }
      }
      this.budgets = newBudgets
    } else {
      this.budgets = [...this.budgets, new Budget('b_' + Date.now(), this.formName, amount, spent, this.formCategoryId, StyleHelper.sPrimary(this.themeColor), '', '', this.formNote, this.formPeriod, notifyEnabled, notifyDaysBefore, 'CNY', Date.now())]
    }

    this.navStack.pop()
    try { this.getUIContext().getPromptAction().showToast({ message: this.editBudgetId !== '' ? this.t.budgetUpdated : this.t.budgetCreated }) } catch (e) { }
  }
}

// ==================== DIALOG弹窗编辑订阅 ====================
@Component
struct EditSubscriptionPage {
  @Consume('navStack') navStack: NavPathStack
  @Consume('subscriptions') subscriptions: Subscription[]
  @Consume('editSubId') editSubId: string
  @Consume('currentLang') currentLang: Language
  @Consume('currentUIStyle') currentUIStyle: string
  @Consume('themeColor') themeColor: string
  private t: TranslationSet = getTranslation('zh')

  @State formName: string = ''
  @State formProvider: string = ''
  @State formAmount: string = ''
  @State formIcon: string = '📦'
  @State formIconColor: string = ''
  @State formNote: string = ''
  @State formNotifyEnabled: boolean = false
  @State formNotifyDaysBefore: string = '3'

  private readonly ICONS: string[] = ['📺', '🎵', '💻', '🎮', '📱', '☁️', '🛡️', '📦', '📰', '🏋️', '🎓', '🚗']

  aboutToAppear(): void {
    this.t = getTranslation(this.currentLang)
    if (this.editSubId !== '') {
      for (let i = 0; i < this.subscriptions.length; i++) {
        if (this.subscriptions[i].id === this.editSubId) {
          const s = this.subscriptions[i]
          this.formName = s.name
          this.formProvider = s.provider
          this.formAmount = s.amount.toString()
          this.formIcon = s.icon
          this.formIconColor = s.iconColor
          this.formNote = s.note
          this.formNotifyEnabled = s.notifyEnabled
          this.formNotifyDaysBefore = s.notifyDaysBefore.toString()
          break
        }
      }
    } else {
      this.formIconColor = StyleHelper.sPrimary(this.themeColor)
    }
  }

  build() {
    NavDestination() {
      Column() {
        Blank().width('100%').layoutWeight(1).onClick(() => { this.navStack.pop() })
        Scroll() {
          Column({ space: 20 }) {
            Text(this.editSubId !== '' ? this.t.editSubscription : this.t.addSubscription)
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor(StyleHelper.sFg(this.currentUIStyle)).width('100%')

            Row({ space: 10 }) {
              Text(this.t.serviceName).fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width(56)
              TextInput({ placeholder: this.t.serviceName, text: this.formName })
                .onChange((value: string) => { this.formName = value }).layoutWeight(1)
            }

            Row({ space: 10 }) {
              Text(this.t.provider).fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width(56)
              TextInput({ placeholder: this.t.provider, text: this.formProvider })
                .onChange((value: string) => { this.formProvider = value }).layoutWeight(1)
            }

            Row({ space: 10 }) {
              Text(this.t.amount).fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width(56)
              TextInput({ placeholder: '0.00', text: this.formAmount })
                .type(InputType.Number)
                .onChange((value: string) => { this.formAmount = value }).layoutWeight(1)
            }

            Text(this.t.selectIcon).fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width('100%')
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.ICONS, (icon: string) => {
                Text(icon)
                  .fontSize(24).width(44).height(44).textAlign(TextAlign.Center).borderRadius(12)
                  .backgroundColor(this.formIcon === icon ? StyleHelper.sPrimaryBg(this.currentUIStyle) : StyleHelper.sChipInactive(this.currentUIStyle))
                  .border(this.formIcon === icon ? { width: 2, color: StyleHelper.sPrimary(this.themeColor), style: BorderStyle.Solid } : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
                  .margin({ right: 6, bottom: 6 })
                  .onClick(() => { this.formIcon = icon })
              }, (icon: string, index: number) => `${icon}_${index}`)
            }

            Row({ space: 10 }) {
              Text(this.t.note).fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width(56)
              TextInput({ placeholder: this.t.addNote, text: this.formNote })
                .onChange((value: string) => { this.formNote = value }).layoutWeight(1)
            }

            // 提醒设置
            Row() {
              Text(this.t.notifyEnabled)
                .fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.formNotifyEnabled })
                .onChange((isOn: boolean) => { this.formNotifyEnabled = isOn })
            }.width('100%')

            if (this.formNotifyEnabled) {
              Row({ space: 10 }) {
                Text(this.t.notifyBefore)
                  .fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width(80)
                TextInput({ placeholder: '3', text: this.formNotifyDaysBefore })
                  .type(InputType.Number)
                  .onChange((value: string) => { this.formNotifyDaysBefore = value })
                  .layoutWeight(1)
              }
            }

            Button(this.editSubId !== '' ? this.t.save : this.t.addSubscription)
              .width('100%').height(44).backgroundColor(StyleHelper.sPrimary(this.themeColor)).fontColor(StyleHelper.sPrimaryFg(this.currentUIStyle))
              .fontSize(16).borderRadius(12).margin({ top: 10, bottom: 20 })
              .onClick(() => { this.onSave() })
          }
          .padding({ left: 20, right: 20, top: 20 })
        }
        .width('100%').height('85%').backgroundColor(StyleHelper.sCardBg(this.currentUIStyle)).borderRadius({ topLeft: 20, topRight: 20 })
      }
      .width('100%').height('100%')
    }
    .mode(NavDestinationMode.DIALOG).hideTitleBar(true).backgroundColor(StyleHelper.sOverlay(this.currentUIStyle))
  }

  private onSave(): void {
    const amount = parseFloat(this.formAmount)
    if (this.formName === '' || isNaN(amount) || amount <= 0) {
      try { this.getUIContext().getPromptAction().showToast({ message: this.t.pleaseEnterServiceName }) } catch (e) { }
      return
    }

    const notifyEnabled = this.formNotifyEnabled
    const notifyDaysBefore = parseInt(this.formNotifyDaysBefore) || 3

    if (this.editSubId !== '') {
      const newSubs: Subscription[] = []
      for (let i = 0; i < this.subscriptions.length; i++) {
        if (this.subscriptions[i].id === this.editSubId) {
          newSubs.push(new Subscription(this.editSubId, this.formProvider, this.formName, amount, 'CNY', this.formIcon, this.formIconColor, '', '', this.formNote, notifyEnabled, notifyDaysBefore, this.subscriptions[i].createdAt))
        } else {
          newSubs.push(this.subscriptions[i])
        }
      }
      this.subscriptions = newSubs
    } else {
      this.subscriptions = [...this.subscriptions, new Subscription('sub_' + Date.now(), this.formProvider, this.formName, amount, 'CNY', this.formIcon, this.formIconColor, '', '', this.formNote, notifyEnabled, notifyDaysBefore, Date.now())]
    }

    this.navStack.pop()
    try { this.getUIContext().getPromptAction().showToast({ message: this.editSubId !== '' ? this.t.subscriptionUpdated : this.t.subscriptionCreated }) } catch (e) { }
  }
}

// ==================== DIALOG弹窗设置页面 ====================
@Component
struct SettingsPage {
  @Consume('navStack') navStack: NavPathStack
  @Consume('currentUIStyle') currentUIStyle: string
  @Consume('currentLang') currentLang: Language
  @Consume('themeColor') themeColor: string
  private t: TranslationSet = getTranslation('zh')

  aboutToAppear(): void {
    this.t = getTranslation(this.currentLang)
  }

  build() {
    NavDestination() {
      Column() {
        Blank().width('100%').layoutWeight(1).onClick(() => { this.navStack.pop() })
        Scroll() {
          Column({ space: 16 }) {
            Text(this.t.settings)
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor(StyleHelper.sFg(this.currentUIStyle)).width('100%')

            // UI风格
            Text(this.t.uiStyle)
              .fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width('100%')
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              Text(this.t.minimalist)
                .fontSize(12).fontColor(this.currentUIStyle === UIStyle.Minimalist ? StyleHelper.sPrimaryFg(this.currentUIStyle) : StyleHelper.sFg(this.currentUIStyle))
                .padding({ left: 14, right: 14, top: 8, bottom: 8 }).borderRadius(16)
                .backgroundColor(this.currentUIStyle === UIStyle.Minimalist ? this.themeColor : StyleHelper.sChipInactive(this.currentUIStyle))
                .margin({ right: 8, bottom: 8 })
                .onClick(() => { this.currentUIStyle = UIStyle.Minimalist })
              Text(this.t.neumorphism)
                .fontSize(12).fontColor(this.currentUIStyle === UIStyle.Neumorphism ? StyleHelper.sPrimaryFg(this.currentUIStyle) : StyleHelper.sFg(this.currentUIStyle))
                .padding({ left: 14, right: 14, top: 8, bottom: 8 }).borderRadius(16)
                .backgroundColor(this.currentUIStyle === UIStyle.Neumorphism ? this.themeColor : StyleHelper.sChipInactive(this.currentUIStyle))
                .margin({ right: 8, bottom: 8 })
                .onClick(() => { this.currentUIStyle = UIStyle.Neumorphism })
              Text(this.t.brutalism)
                .fontSize(12).fontColor(this.currentUIStyle === UIStyle.Brutalism ? StyleHelper.sPrimaryFg(this.currentUIStyle) : StyleHelper.sFg(this.currentUIStyle))
                .padding({ left: 14, right: 14, top: 8, bottom: 8 }).borderRadius(16)
                .backgroundColor(this.currentUIStyle === UIStyle.Brutalism ? this.themeColor : StyleHelper.sChipInactive(this.currentUIStyle))
                .margin({ right: 8, bottom: 8 })
                .onClick(() => { this.currentUIStyle = UIStyle.Brutalism })
              Text(this.t.cyberpunk)
                .fontSize(12).fontColor(this.currentUIStyle === UIStyle.Cyberpunk ? StyleHelper.sPrimaryFg(this.currentUIStyle) : StyleHelper.sFg(this.currentUIStyle))
                .padding({ left: 14, right: 14, top: 8, bottom: 8 }).borderRadius(16)
                .backgroundColor(this.currentUIStyle === UIStyle.Cyberpunk ? this.themeColor : StyleHelper.sChipInactive(this.currentUIStyle))
                .margin({ right: 8, bottom: 8 })
                .onClick(() => { this.currentUIStyle = UIStyle.Cyberpunk })
            }

            // 货币
            Row() {
              Text(this.t.currency)
                .fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).layoutWeight(1)
              Text('CNY ¥')
                .fontSize(14).fontColor(StyleHelper.sFgMuted(this.currentUIStyle))
            }
            .width('100%').padding(14).backgroundColor(StyleHelper.sSecondaryBg(this.currentUIStyle)).borderRadius(12)

            // 语言
            Text('Language / 语言')
              .fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width('100%')
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              Text('中文')
                .fontSize(12).fontColor(this.currentLang === 'zh' ? StyleHelper.sPrimaryFg(this.currentUIStyle) : StyleHelper.sFg(this.currentUIStyle))
                .padding({ left: 14, right: 14, top: 8, bottom: 8 }).borderRadius(16)
                .backgroundColor(this.currentLang === 'zh' ? this.themeColor : StyleHelper.sChipInactive(this.currentUIStyle))
                .margin({ right: 8, bottom: 8 })
                .onClick(() => { this.currentLang = 'zh'; this.t = getTranslation('zh') })
              Text('English')
                .fontSize(12).fontColor(this.currentLang === 'en' ? StyleHelper.sPrimaryFg(this.currentUIStyle) : StyleHelper.sFg(this.currentUIStyle))
                .padding({ left: 14, right: 14, top: 8, bottom: 8 }).borderRadius(16)
                .backgroundColor(this.currentLang === 'en' ? this.themeColor : StyleHelper.sChipInactive(this.currentUIStyle))
                .margin({ right: 8, bottom: 8 })
                .onClick(() => { this.currentLang = 'en'; this.t = getTranslation('en') })
            }

            // 主题色
            Text(this.t.themeColor)
              .fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).width('100%')
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              Column() {
                Circle({ width: 28, height: 28 }).fill('#3B82F6')
                  .stroke(this.themeColor === '#3B82F6' ? StyleHelper.sFg(this.currentUIStyle) : Color.Transparent)
                  .strokeWidth(this.themeColor === '#3B82F6' ? 3 : 0)
              }.padding(6).onClick(() => { this.themeColor = '#3B82F6' })
              Column() {
                Circle({ width: 28, height: 28 }).fill('#F43F5E')
                  .stroke(this.themeColor === '#F43F5E' ? StyleHelper.sFg(this.currentUIStyle) : Color.Transparent)
                  .strokeWidth(this.themeColor === '#F43F5E' ? 3 : 0)
              }.padding(6).onClick(() => { this.themeColor = '#F43F5E' })
              Column() {
                Circle({ width: 28, height: 28 }).fill('#22C55E')
                  .stroke(this.themeColor === '#22C55E' ? StyleHelper.sFg(this.currentUIStyle) : Color.Transparent)
                  .strokeWidth(this.themeColor === '#22C55E' ? 3 : 0)
              }.padding(6).onClick(() => { this.themeColor = '#22C55E' })
              Column() {
                Circle({ width: 28, height: 28 }).fill('#8B5CF6')
                  .stroke(this.themeColor === '#8B5CF6' ? StyleHelper.sFg(this.currentUIStyle) : Color.Transparent)
                  .strokeWidth(this.themeColor === '#8B5CF6' ? 3 : 0)
              }.padding(6).onClick(() => { this.themeColor = '#8B5CF6' })
              Column() {
                Circle({ width: 28, height: 28 }).fill('#F59E0B')
                  .stroke(this.themeColor === '#F59E0B' ? StyleHelper.sFg(this.currentUIStyle) : Color.Transparent)
                  .strokeWidth(this.themeColor === '#F59E0B' ? 3 : 0)
              }.padding(6).onClick(() => { this.themeColor = '#F59E0B' })
              Column() {
                Circle({ width: 28, height: 28 }).fill('#14B8A6')
                  .stroke(this.themeColor === '#14B8A6' ? StyleHelper.sFg(this.currentUIStyle) : Color.Transparent)
                  .strokeWidth(this.themeColor === '#14B8A6' ? 3 : 0)
              }.padding(6).onClick(() => { this.themeColor = '#14B8A6' })
            }

            // 版本
            Row() {
              Text(this.t.progress)
                .fontSize(16).fontColor(StyleHelper.sFg(this.currentUIStyle)).layoutWeight(1)
              Text('1.0.0')
                .fontSize(14).fontColor(StyleHelper.sFgMuted(this.currentUIStyle))
            }
            .width('100%').padding(14).backgroundColor(StyleHelper.sSecondaryBg(this.currentUIStyle)).borderRadius(12)

            // 清除数据
            Button(this.t.clearAll)
              .width('100%').height(44).backgroundColor(StyleHelper.sExpense(this.currentUIStyle)).fontColor(StyleHelper.sPrimaryFg(this.currentUIStyle))
              .fontSize(16).borderRadius(12).margin({ top: 10, bottom: 20 })
              .onClick(() => {
                storageUtil.clear().then(() => {
                  this.navStack.pop()
                }).catch((e: Error) => {
                  console.error('clear failed:' + String(e))
                })
              })
          }
          .padding({ left: 20, right: 20, top: 20 })
        }
        .width('100%').height('70%').backgroundColor(StyleHelper.sCardBg(this.currentUIStyle)).borderRadius({ topLeft: 20, topRight: 20 })
      }
      .width('100%').height('100%')
    }
    .mode(NavDestinationMode.DIALOG).hideTitleBar(true).backgroundColor(StyleHelper.sOverlay(this.currentUIStyle))
  }
}
