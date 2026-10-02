/**
 * TransactionHall - 交易大厅
 * 使用原生 List + ListItemGroup 渲染按日期分组的交易流水
 * 顶部过滤器支持：类型 / 分类 / 钱包 / 平台（底部弹窗选择器）
 * 支持搜索、点击编辑、滑动删除
 */
import { Transaction } from '../model/Transaction'
import { Wallet } from '../model/Wallet'
import { Category, DEFAULT_EXPENSE_CATEGORIES, DEFAULT_INCOME_CATEGORIES } from '../model/Category'
import { Platform, DEFAULT_PLATFORMS } from '../model/Platform'
import { TransactionType, TransactionTypeLabel, getCurrencySymbol } from '../constants/CurrencyConst'
import { UIStyle, PageBackgroundMap, PrimaryTextColorMap, SecondaryTextColorMap, CardBackgroundMap, CardBorderMap, RadiusMap, IncomeColorMap, ExpenseColorMap, ChipActiveMap, ChipInactiveMap, DividerColorMap, PrimaryColorMap, PrimaryForegroundMap, SecondaryBackgroundMap } from '../constants/UIStyleConst'
import { UniCard } from '../components/UniCard'
import { UniInput } from '../components/UniInput'
import { ImagePreviewModal } from '../components/ImagePreviewModal'
import { getCurrentLanguage, getTranslation } from '../constants/I18n'
import { CategoryIcon } from '../components/CategoryIcon'
import { AppIcon } from '../components/AppIcon'

// ==================== 常量 ====================
const FILTER_ALL: string = 'all'
const FILTER_EXPENSE: string = 'expense'
const FILTER_INCOME: string = 'income'
const FILTER_TRANSFER: string = 'transfer'

// 类型过滤选项
class TypeFilterOption {
  key: string = ''
  label: string = ''

  constructor(key: string, label: string) {
    this.key = key
    this.label = label
  }
}

const TYPE_FILTERS: TypeFilterOption[] = [
  new TypeFilterOption(FILTER_ALL, ''),
  new TypeFilterOption(FILTER_EXPENSE, ''),
  new TypeFilterOption(FILTER_INCOME, ''),
  new TypeFilterOption(FILTER_TRANSFER, '')
]

// 日期分组数据
class DateGroup {
  dateKey: string = ''
  displayLabel: string = ''
  transactions: Transaction[] = []

  constructor(dateKey: string, displayLabel: string, transactions: Transaction[]) {
    this.dateKey = dateKey
    this.displayLabel = displayLabel
    this.transactions = transactions
  }
}

// ==================== 模块级辅助函数 ====================

/**
 * 为 hex 颜色添加透明度，返回 rgba 格式
 */
function colorWithAlpha(hexColor: string, alpha: number): string {
  if (!hexColor || hexColor.length < 7) {
    return `rgba(128, 128, 128, ${alpha})`
  }
  const r = parseInt(hexColor.substring(1, 3), 16)
  const g = parseInt(hexColor.substring(3, 5), 16)
  const b = parseInt(hexColor.substring(5, 7), 16)
  return `rgba(${r}, ${g}, ${b}, ${alpha})`
}

/**
 * 合并所有默认分类
 */
function getAllCategories(): Category[] {
  const result: Category[] = []
  for (let i = 0; i < DEFAULT_EXPENSE_CATEGORIES.length; i++) {
    result.push(DEFAULT_EXPENSE_CATEGORIES[i])
  }
  for (let i = 0; i < DEFAULT_INCOME_CATEGORIES.length; i++) {
    result.push(DEFAULT_INCOME_CATEGORIES[i])
  }
  return result
}

/**
 * 根据过滤器 key 获取国际化标签
 */
function getTypeLabel(key: string): string {
  const t = getTranslation(getCurrentLanguage())
  switch (key) {
    case FILTER_ALL:
      return t.allRecords
    case FILTER_EXPENSE:
      return t.expenseOnly
    case FILTER_INCOME:
      return t.incomeOnly
    case FILTER_TRANSFER:
      return t.transferOnly
    default:
      return key
  }
}

// ==================== 类型选择器弹窗 ====================
@CustomDialog
struct TypePickerDialog {
  controller: CustomDialogController
  styleValue: string = UIStyle.Minimalist
  currentFilter: string = FILTER_ALL
  onSelected: (filter: string) => void = () => {}
  private getT() { return getTranslation(getCurrentLanguage()) }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.getT().selectType)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(PrimaryTextColorMap.get(this.styleValue) ?? '#1A1A2E')
        Blank()
        AppIcon({ icon: 'x', fontSize: 18, fontColor: SecondaryTextColorMap.get(this.styleValue) ?? '#8E8E93' })
          .padding(8)
          .onClick(() => {
            this.controller.close()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 12, top: 20, bottom: 12 })

      // 选项列表
      Scroll() {
        Column({ space: 4 }) {
          ForEach(TYPE_FILTERS, (f: TypeFilterOption) => {
            Row() {
              Text(getTypeLabel(f.key))
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(PrimaryTextColorMap.get(this.styleValue) ?? '#1A1A2E')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .borderRadius(RadiusMap.get(this.styleValue) ?? 16)
            .backgroundColor(this.currentFilter === f.key
              ? colorWithAlpha(PrimaryColorMap.get(this.styleValue) ?? '#3B82F6', 0.1)
              : Color.Transparent)
            .border(this.currentFilter === f.key
              ? { width: 1, color: PrimaryColorMap.get(this.styleValue) ?? '#3B82F6', style: BorderStyle.Solid }
              : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
            .onClick(() => {
              this.onSelected(f.key)
              this.controller.close()
            })
          }, (f: TypeFilterOption) => f.key)
        }
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .scrollBar(BarState.Auto)
      .constraintSize({ maxHeight: 320 })
    }
    .width('100%')
    .borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor(CardBackgroundMap.get(this.styleValue) ?? '#FFFFFF')
  }
}

// ==================== 分类选择器弹窗 ====================
@CustomDialog
struct CategoryPickerDialog {
  controller: CustomDialogController
  styleValue: string = UIStyle.Minimalist
  selectedCategoryId: string = ''
  onSelected: (categoryId: string) => void = () => {}
  private getT() { return getTranslation(getCurrentLanguage()) }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.getT().selectCategory)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(PrimaryTextColorMap.get(this.styleValue) ?? '#1A1A2E')
        Blank()
        AppIcon({ icon: 'x', fontSize: 18, fontColor: SecondaryTextColorMap.get(this.styleValue) ?? '#8E8E93' })
          .padding(8)
          .onClick(() => {
            this.controller.close()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 12, top: 20, bottom: 12 })

      // 分类列表
      Scroll() {
        Column({ space: 2 }) {
          ForEach(getAllCategories(), (c: Category) => {
            Row() {
              // 分类图标（带颜色背景）
              CategoryIcon({ icon: c.icon, color: c.color || '#94a3b8', iconSize: 16, containerSize: 32 })
                .margin({ right: 12 })

              Text(c.name)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(PrimaryTextColorMap.get(this.styleValue) ?? '#1A1A2E')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .borderRadius(RadiusMap.get(this.styleValue) ?? 16)
            .backgroundColor(this.selectedCategoryId === c.id
              ? colorWithAlpha(PrimaryColorMap.get(this.styleValue) ?? '#3B82F6', 0.1)
              : Color.Transparent)
            .border(this.selectedCategoryId === c.id
              ? { width: 1, color: PrimaryColorMap.get(this.styleValue) ?? '#3B82F6', style: BorderStyle.Solid }
              : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
            .onClick(() => {
              this.onSelected(c.id)
              this.controller.close()
            })
          }, (c: Category) => c.id)
        }
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .scrollBar(BarState.Auto)
      .constraintSize({ maxHeight: 400 })
    }
    .width('100%')
    .borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor(CardBackgroundMap.get(this.styleValue) ?? '#FFFFFF')
  }
}

// ==================== 钱包选择器弹窗 ====================
@CustomDialog
struct WalletPickerDialog {
  controller: CustomDialogController
  styleValue: string = UIStyle.Minimalist
  wallets: Wallet[] = []
  selectedWalletId: string = ''
  onSelected: (walletId: string) => void = () => {}
  private getT() { return getTranslation(getCurrentLanguage()) }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.getT().selectWallet)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(PrimaryTextColorMap.get(this.styleValue) ?? '#1A1A2E')
        Blank()
        AppIcon({ icon: 'x', fontSize: 18, fontColor: SecondaryTextColorMap.get(this.styleValue) ?? '#8E8E93' })
          .padding(8)
          .onClick(() => {
            this.controller.close()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 12, top: 20, bottom: 12 })

      // 钱包列表
      Scroll() {
        Column({ space: 2 }) {
          ForEach(this.wallets, (w: Wallet) => {
            Row() {
              // 钱包图标（带颜色背景）
              Stack() {
                Text(w.icon || '💰')
                  .fontSize(18)
              }
              .width(36)
              .height(36)
              .borderRadius(12)
              .backgroundColor(colorWithAlpha(w.color || '#94a3b8', 0.125))
              .alignContent(Alignment.Center)
              .margin({ right: 12 })

              Text(w.name)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(PrimaryTextColorMap.get(this.styleValue) ?? '#1A1A2E')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .borderRadius(RadiusMap.get(this.styleValue) ?? 16)
            .backgroundColor(this.selectedWalletId === w.id
              ? colorWithAlpha(PrimaryColorMap.get(this.styleValue) ?? '#3B82F6', 0.1)
              : Color.Transparent)
            .border(this.selectedWalletId === w.id
              ? { width: 1, color: PrimaryColorMap.get(this.styleValue) ?? '#3B82F6', style: BorderStyle.Solid }
              : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
            .onClick(() => {
              this.onSelected(w.id)
              this.controller.close()
            })
          }, (w: Wallet) => w.id)
        }
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .scrollBar(BarState.Auto)
      .constraintSize({ maxHeight: 400 })
    }
    .width('100%')
    .borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor(CardBackgroundMap.get(this.styleValue) ?? '#FFFFFF')
  }
}

// ==================== 平台选择器弹窗 ====================
@CustomDialog
struct PlatformPickerDialog {
  controller: CustomDialogController
  styleValue: string = UIStyle.Minimalist
  platforms: Platform[] = []
  selectedPlatformId: string = ''
  onSelected: (platformId: string) => void = () => {}
  private getT() { return getTranslation(getCurrentLanguage()) }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.getT().selectPlatform)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(PrimaryTextColorMap.get(this.styleValue) ?? '#1A1A2E')
        Blank()
        AppIcon({ icon: 'x', fontSize: 18, fontColor: SecondaryTextColorMap.get(this.styleValue) ?? '#8E8E93' })
          .padding(8)
          .onClick(() => {
            this.controller.close()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 12, top: 20, bottom: 12 })

      // 平台列表
      Scroll() {
        Column({ space: 2 }) {
          ForEach(this.platforms, (p: Platform) => {
            Row() {
              // 平台图标（带颜色背景）
              Stack() {
                Text(p.icon || '💳')
                  .fontSize(18)
              }
              .width(36)
              .height(36)
              .borderRadius(12)
              .backgroundColor(colorWithAlpha(p.color || '#94a3b8', 0.125))
              .alignContent(Alignment.Center)
              .margin({ right: 12 })

              Text(p.name)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(PrimaryTextColorMap.get(this.styleValue) ?? '#1A1A2E')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .borderRadius(RadiusMap.get(this.styleValue) ?? 16)
            .backgroundColor(this.selectedPlatformId === p.id
              ? colorWithAlpha(PrimaryColorMap.get(this.styleValue) ?? '#3B82F6', 0.1)
              : Color.Transparent)
            .border(this.selectedPlatformId === p.id
              ? { width: 1, color: PrimaryColorMap.get(this.styleValue) ?? '#3B82F6', style: BorderStyle.Solid }
              : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
            .onClick(() => {
              this.onSelected(p.id)
              this.controller.close()
            })
          }, (p: Platform) => p.id)
        }
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .scrollBar(BarState.Auto)
      .constraintSize({ maxHeight: 400 })
    }
    .width('100%')
    .borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor(CardBackgroundMap.get(this.styleValue) ?? '#FFFFFF')
  }
}

// ==================== 交易大厅主组件 ====================
@Component
export struct TransactionHall {
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist
  private getT() { return getTranslation(getCurrentLanguage()) }

  // 接收父组件传入的数据
  @Prop transactions: Transaction[] = []
  @Prop wallets: Wallet[] = []
  @Prop platforms: Platform[] = []

  // 回调
  onEditTransaction: (tx: Transaction) => void = () => {}
  onDeleteTransaction: (txId: string) => void = () => {}

  // 过滤器状态
  @State currentFilter: string = FILTER_ALL
  @State selectedCategoryId: string = ''
  @State selectedWalletId: string = ''
  @State selectedPlatformId: string = ''

  // 搜索状态
  @State searchText: string = ''
  @State showSearch: boolean = false

  // 图片预览状态
  @State previewImageUri: string = ''
  private imagePreviewController: CustomDialogController = new CustomDialogController({
    builder: ImagePreviewModal({
      imageUri: this.previewImageUri
    }),
    customStyle: true,
    alignment: DialogAlignment.Center
  })

  // 选择器弹窗控制器
  private typePickerController: CustomDialogController = new CustomDialogController({
    builder: TypePickerDialog({
      styleValue: this.currentStyle,
      currentFilter: this.currentFilter,
      onSelected: (filter: string) => {
        this.onTypeFilterSelected(filter)
      }
    }),
    customStyle: true,
    alignment: DialogAlignment.Bottom
  })

  private categoryPickerController: CustomDialogController = new CustomDialogController({
    builder: CategoryPickerDialog({
      styleValue: this.currentStyle,
      selectedCategoryId: this.selectedCategoryId,
      onSelected: (categoryId: string) => {
        this.onCategorySelected(categoryId)
      }
    }),
    customStyle: true,
    alignment: DialogAlignment.Bottom
  })

  private walletPickerController: CustomDialogController = new CustomDialogController({
    builder: WalletPickerDialog({
      styleValue: this.currentStyle,
      wallets: this.wallets,
      selectedWalletId: this.selectedWalletId,
      onSelected: (walletId: string) => {
        this.onWalletSelected(walletId)
      }
    }),
    customStyle: true,
    alignment: DialogAlignment.Bottom
  })

  private platformPickerController: CustomDialogController = new CustomDialogController({
    builder: PlatformPickerDialog({
      styleValue: this.currentStyle,
      platforms: this.platforms,
      selectedPlatformId: this.selectedPlatformId,
      onSelected: (platformId: string) => {
        this.onPlatformSelected(platformId)
      }
    }),
    customStyle: true,
    alignment: DialogAlignment.Bottom
  })

  // ==================== build ====================
  build() {
    Column() {
      // ---- 页面标题 ----
      this.TitleBar()

      // ---- 搜索栏 ----
      if (this.showSearch) {
        this.SearchBar()
      }

      // ---- 过滤器 ----
      this.FilterBar()

      // ---- 交易列表（按日期分组） ----
      if (this.getDateGroups().length === 0) {
        Column() {
          Text(this.getT().noRecords)
            .fontSize(14)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .margin({ top: 80 })
          Text(this.getT().addFirst)
            .fontSize(12)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .margin({ top: 4 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 0 }) {
          ForEach(this.getDateGroups(), (group: DateGroup) => {
            ListItemGroup({
              header: this.DateGroupHeader(group.displayLabel, group.transactions),
              space: 6
            }) {
              ForEach(group.transactions, (tx: Transaction) => {
                ListItem() {
                  if (tx.type === TransactionType.Transfer) {
                    this.TransferItem(tx)
                  } else {
                    this.TransactionItem(tx)
                  }
                }
                .swipeAction({ end: this.DeleteSwipeAction(tx.id) })
              }, (tx: Transaction) => tx.id)
            }
          }, (group: DateGroup) => group.dateKey)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#F5F5F7')
  }

  // ==================== 标题栏 ====================
  @Builder
  TitleBar() {
    Row() {
      Text(this.getT().transactionHallTitle)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

      Blank()

      // 搜索按钮
      if (this.showSearch) {
        AppIcon({ icon: 'x', fontSize: 18, fontColor: PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E' })
          .padding(8)
          .onClick(() => {
            this.showSearch = false
            this.searchText = ''
          })
      } else {
        AppIcon({ icon: 'search', fontSize: 18, fontColor: PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E' })
          .padding(8)
          .onClick(() => {
            this.showSearch = true
          })
      }
    }
    .width('100%')
    .padding({ left: 20, right: 12, top: 16, bottom: 8 })
  }

  // ==================== 搜索栏 ====================
  @Builder
  SearchBar() {
    Row() {
      UniInput({
        textValue: $searchText,
        placeholder: this.getT().searchPlaceholder,
        inputType: InputType.Normal,
        heightValue: 40,
        marginValue: 0
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 8 })
  }

  // ==================== 过滤器 ====================
  @Builder
  FilterBar() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
      // 类型过滤按钮
      Row() {
        AppIcon({ icon: 'filter', fontSize: 16 })
          .margin({ right: 4 })
        Text(this.getTypeFilterLabel())
          .fontSize(13)
          .fontColor(this.currentFilter !== FILTER_ALL
            ? (PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
            : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'))
        AppIcon({ icon: 'chevron-down', fontSize: 12, fontColor: this.currentFilter !== FILTER_ALL
          ? (PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
          : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93') })
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 20)
      .backgroundColor(this.currentFilter !== FILTER_ALL
        ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
        : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
      .border(this.currentFilter !== FILTER_ALL
        ? { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
        : { width: 1, color: DividerColorMap.get(this.currentStyle) ?? '#E0E0E0', style: BorderStyle.Solid })
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.typePickerController.open()
      })

      // 分类过滤按钮
      Row() {
        if (this.selectedCategoryId !== '') {
          Text(this.getSelectedCategoryIcon())
            .fontSize(12)
            .margin({ right: 4 })
          Text(this.getSelectedCategoryName())
            .fontSize(13)
            .fontColor(PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
        } else {
          Text(this.getT().selectCategory)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          AppIcon({ icon: 'chevron-down', fontSize: 12, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })
        }
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 20)
      .backgroundColor(this.selectedCategoryId !== ''
        ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
        : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
      .border(this.selectedCategoryId !== ''
        ? { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
        : { width: 1, color: DividerColorMap.get(this.currentStyle) ?? '#E0E0E0', style: BorderStyle.Solid })
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.categoryPickerController.open()
      })

      // 钱包过滤按钮
      Row() {
        if (this.selectedWalletId !== '') {
          Text(this.getSelectedWalletIcon())
            .fontSize(12)
            .margin({ right: 4 })
          Text(this.getSelectedWalletName())
            .fontSize(13)
            .fontColor(PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
        } else {
          Text(this.getT().selectWallet)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          AppIcon({ icon: 'chevron-down', fontSize: 12, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })
        }
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 20)
      .backgroundColor(this.selectedWalletId !== ''
        ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
        : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
      .border(this.selectedWalletId !== ''
        ? { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
        : { width: 1, color: DividerColorMap.get(this.currentStyle) ?? '#E0E0E0', style: BorderStyle.Solid })
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.walletPickerController.open()
      })

      // 平台过滤按钮
      Row() {
        if (this.selectedPlatformId !== '') {
          Text(this.getSelectedPlatformIcon())
            .fontSize(12)
            .margin({ right: 4 })
          Text(this.getSelectedPlatformName())
            .fontSize(13)
            .fontColor(PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
        } else {
          Text(this.getT().selectPlatform)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          AppIcon({ icon: 'chevron-down', fontSize: 12, fontColor: SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93' })
        }
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 20)
      .backgroundColor(this.selectedPlatformId !== ''
        ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
        : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
      .border(this.selectedPlatformId !== ''
        ? { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
        : { width: 1, color: DividerColorMap.get(this.currentStyle) ?? '#E0E0E0', style: BorderStyle.Solid })
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.platformPickerController.open()
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 12 })
  }

  // ==================== 日期分组头 ====================
  @Builder
  DateGroupHeader(label: string, txs: Transaction[]) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

      Blank()

      // 当日小计
      Text(this.getDaySummary(txs))
        .fontSize(12)
        .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 12, bottom: 6 })
  }

  // ==================== 普通交易项 ====================
  @Builder
  TransactionItem(tx: Transaction) {
    Column() {
      UniCard({ paddingValue: 14 }) {
        Row() {
          // 分类图标（带颜色背景圆）
          CategoryIcon({ icon: this.getCategoryIcon(tx), color: this.getCategoryColor(tx), iconSize: 20, containerSize: 40 })
            .margin({ right: 12 })

          // 分类名 + 平台标签 + 日期时间
          Column() {
            Row() {
              Text(this.getCategoryName(tx))
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              // 平台标签
              if (tx.platformId && tx.platformId !== '') {
                Text(this.getPlatformName(tx.platformId))
                  .fontSize(10)
                  .fontColor(Color.White)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .borderRadius(8)
                  .backgroundColor(this.getPlatformColor(tx.platformId))
                  .margin({ left: 6 })
                  .constraintSize({ maxWidth: 80 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }

            // 日期时间 · 钱包名 · 备注
            Row() {
              Text(this.formatDateTimeDisplay(tx.datetime))
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              if (tx.walletId && tx.walletId !== '') {
                Text(' · ' + this.getWalletName(tx.walletId))
                  .fontSize(12)
                  .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              }
              if (tx.note && tx.note !== '') {
                Text(' · ' + tx.note)
                  .fontSize(12)
                  .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 图片缩略图
          if (tx.hasImage && tx.imageUri !== '') {
            Image(tx.imageUri)
              .width(40)
              .height(40)
              .objectFit(ImageFit.Cover)
              .borderRadius(6)
              .margin({ right: 12 })
              .onClick(() => {
                this.showImagePreview(tx.imageUri)
              })
          }

          // 金额 + 币种代码
          Column() {
            Row() {
              Text(this.formatAmount(tx))
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getAmountColor(tx))
              Text(' ' + tx.currency)
                .fontSize(10)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            }
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
      }
    }
    .onClick(() => {
      this.onEditTransaction(tx)
    })
  }

  // ==================== 转账交易项 ====================
  @Builder
  TransferItem(tx: Transaction) {
    Column() {
      UniCard({ paddingValue: 14 }) {
        Row() {
          // 转账图标（带颜色背景圆）
          Stack() {
            AppIcon({ icon: 'arrow-right', fontSize: 18, fontColor: PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6' })
          }
          .width(40)
          .height(40)
          .borderRadius(16)
          .backgroundColor(colorWithAlpha(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6', 0.1))
          .alignContent(Alignment.Center)
          .margin({ right: 12 })

          // 转账信息
          Column() {
            Text(this.getT().transfer)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')

            // fromWallet → toWallet · 备注
            Row() {
              Text(this.getWalletName(tx.fromWalletId))
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              Text(' → ')
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              Text(this.getWalletName(tx.toWalletId))
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
              if (tx.note && tx.note !== '') {
                Text(' · ' + tx.note)
                  .fontSize(12)
                  .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 双金额显示
          Column() {
            Text(`-${getCurrencySymbol(tx.fromCurrency || tx.currency)}${(tx.fromAmount || tx.amount).toFixed(2)}`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')

            if (tx.toAmount && tx.toAmount > 0) {
              Text(`+${getCurrencySymbol(tx.toCurrency || '')}${tx.toAmount.toFixed(2)}`)
                .fontSize(12)
                .fontColor(IncomeColorMap.get(this.currentStyle) ?? '#22C55E')
                .margin({ top: 2 })
            }
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
      }
    }
    .onClick(() => {
      this.onEditTransaction(tx)
    })
  }

  // ==================== 滑动删除按钮 ====================
  @Builder
  DeleteSwipeAction(txId: string) {
    Row() {
      Column() {
        AppIcon({ icon: 'trash-2', fontSize: 16, fontColor: '#FFFFFF' })

        Text(this.getT().deleteLabel)
          .fontSize(11)
          .fontColor(Color.White)
          .margin({ top: 2 })
      }
      .width(70)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#E53935')
      .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 8)
    }
    .padding({ left: 8 })
    .onClick(() => {
      this.onDeleteTransaction(txId)
    })
  }

  // ==================== 过滤器选择回调 ====================

  private onTypeFilterSelected(filter: string): void {
    this.currentFilter = filter
    // 选择类型时清除分类/钱包/平台过滤
    this.selectedCategoryId = ''
    this.selectedWalletId = ''
    this.selectedPlatformId = ''
  }

  private onCategorySelected(categoryId: string): void {
    this.selectedCategoryId = categoryId
    // 选择分类时清除钱包/平台过滤，类型设为全部
    this.currentFilter = FILTER_ALL
    this.selectedWalletId = ''
    this.selectedPlatformId = ''
  }

  private onWalletSelected(walletId: string): void {
    this.selectedWalletId = walletId
    // 选择钱包时清除分类/平台过滤，类型设为全部
    this.currentFilter = FILTER_ALL
    this.selectedCategoryId = ''
    this.selectedPlatformId = ''
  }

  private onPlatformSelected(platformId: string): void {
    this.selectedPlatformId = platformId
    // 选择平台时清除分类/钱包过滤，类型设为全部
    this.currentFilter = FILTER_ALL
    this.selectedCategoryId = ''
    this.selectedWalletId = ''
  }

  // ==================== 数据过滤与分组 ====================

  /**
   * 根据过滤器和搜索词返回交易列表
   */
  private getFilteredList(): Transaction[] {
    let list = this.transactions

    // 按类型过滤
    if (this.currentFilter !== FILTER_ALL) {
      const filterStr: string = this.currentFilter
      list = list.filter((tx: Transaction) => {
        if (filterStr === FILTER_TRANSFER) {
          return tx.type === TransactionType.Transfer
        }
        return tx.type === filterStr
      })
    }

    // 当分类/钱包/平台过滤激活时，排除转账
    if (this.selectedCategoryId !== '' || this.selectedWalletId !== '' || this.selectedPlatformId !== '') {
      list = list.filter((tx: Transaction) => {
        return tx.type !== TransactionType.Transfer
      })
    }

    // 按分类过滤
    if (this.selectedCategoryId !== '') {
      const catId = this.selectedCategoryId
      list = list.filter((tx: Transaction) => {
        return tx.category === catId
      })
    }

    // 按钱包过滤
    if (this.selectedWalletId !== '') {
      const walletId = this.selectedWalletId
      list = list.filter((tx: Transaction) => {
        return tx.walletId === walletId
      })
    }

    // 按平台过滤
    if (this.selectedPlatformId !== '') {
      const platId = this.selectedPlatformId
      list = list.filter((tx: Transaction) => {
        return tx.platformId === platId
      })
    }

    // 按搜索词过滤
    if (this.searchText !== '') {
      const keyword = this.searchText.toLowerCase()
      list = list.filter((tx: Transaction) => {
        const noteMatch = tx.note && tx.note.toLowerCase().includes(keyword)
        const catMatch = this.getCategoryName(tx).toLowerCase().includes(keyword)
        const walletMatch = this.getWalletName(tx.walletId).toLowerCase().includes(keyword)
        return noteMatch || catMatch || walletMatch
      })
    }

    // Sort by datetime desc, then by createdAt desc
    list.sort((a: Transaction, b: Transaction) => {
      const timeDiff = new Date(b.datetime).getTime() - new Date(a.datetime).getTime()
      if (timeDiff !== 0) return timeDiff
      return b.createdAt - a.createdAt
    })

    return list
  }

  /**
   * 将过滤后的交易列表按日期分组
   */
  private getDateGroups(): DateGroup[] {
    const filtered = this.getFilteredList()
    if (filtered.length === 0) {
      return []
    }

    const groupMap: Map<string, Transaction[]> = new Map()
    const dateOrder: string[] = []

    for (let i = 0; i < filtered.length; i++) {
      const tx = filtered[i]
      const dateKey = this.getDateKey(tx.datetime)
      if (!groupMap.has(dateKey)) {
        groupMap.set(dateKey, [])
        dateOrder.push(dateKey)
      }
      const group = groupMap.get(dateKey)
      if (group !== undefined) {
        group.push(tx)
      }
    }

    const groups: DateGroup[] = []
    for (let i = 0; i < dateOrder.length; i++) {
      const key = dateOrder[i]
      const groupList = groupMap.get(key)
      if (groupList !== undefined) {
        groups.push(new DateGroup(
          key,
          this.getDateLabel(key),
          groupList
        ))
      }
    }

    return groups
  }

  // ==================== 辅助方法 ====================

  private showImagePreview(uri: string): void {
    this.previewImageUri = uri
    this.imagePreviewController.open()
  }

  /**
   * 获取类型过滤器的当前标签
   */
  private getTypeFilterLabel(): string {
    return getTypeLabel(this.currentFilter)
  }

  /**
   * 获取已选分类的图标
   */
  private getSelectedCategoryIcon(): string {
    const cat = this.getCategoryById(this.selectedCategoryId)
    return cat.icon || '📌'
  }

  /**
   * 获取已选分类的名称
   */
  private getSelectedCategoryName(): string {
    const cat = this.getCategoryById(this.selectedCategoryId)
    return cat.name || this.getT().selectCategory
  }

  /**
   * 获取已选钱包的图标
   */
  private getSelectedWalletIcon(): string {
    const wallet = this.getWalletById(this.selectedWalletId)
    return wallet.icon || '💰'
  }

  /**
   * 获取已选钱包的名称
   */
  private getSelectedWalletName(): string {
    const wallet = this.getWalletById(this.selectedWalletId)
    return wallet.name || this.getT().selectWallet
  }

  /**
   * 获取已选平台的图标
   */
  private getSelectedPlatformIcon(): string {
    const plat = this.getPlatformById(this.selectedPlatformId)
    return plat.icon || '💳'
  }

  /**
   * 获取已选平台的名称
   */
  private getSelectedPlatformName(): string {
    const plat = this.getPlatformById(this.selectedPlatformId)
    return plat.name || this.getT().selectPlatform
  }

  /**
   * 根据 ID 查找分类
   */
  private getCategoryById(categoryId: string): Category {
    for (let i = 0; i < DEFAULT_EXPENSE_CATEGORIES.length; i++) {
      if (DEFAULT_EXPENSE_CATEGORIES[i].id === categoryId) {
        return DEFAULT_EXPENSE_CATEGORIES[i]
      }
    }
    for (let i = 0; i < DEFAULT_INCOME_CATEGORIES.length; i++) {
      if (DEFAULT_INCOME_CATEGORIES[i].id === categoryId) {
        return DEFAULT_INCOME_CATEGORIES[i]
      }
    }
    return new Category('', '', '', '#94a3b8', 0)
  }

  /**
   * 根据 ID 查找钱包
   */
  private getWalletById(walletId: string): Wallet {
    for (let i = 0; i < this.wallets.length; i++) {
      if (this.wallets[i].id === walletId) {
        return this.wallets[i]
      }
    }
    return new Wallet('', '', '#94a3b8', '💰', 'CNY', 0)
  }

  /**
   * 根据 ID 查找平台
   */
  private getPlatformById(platformId: string): Platform {
    for (let i = 0; i < this.platforms.length; i++) {
      if (this.platforms[i].id === platformId) {
        return this.platforms[i]
      }
    }
    return new Platform('', '', '', '#94a3b8', 0)
  }

  /**
   * 获取交易分类图标
   */
  private getCategoryIcon(tx: Transaction): string {
    if (tx.type === TransactionType.Transfer) {
      return '🔄'
    }
    const categories = tx.type === TransactionType.Expense
      ? DEFAULT_EXPENSE_CATEGORIES
      : DEFAULT_INCOME_CATEGORIES
    for (let i = 0; i < categories.length; i++) {
      if (categories[i].id === tx.category) {
        return categories[i].icon
      }
    }
    return '📌'
  }

  /**
   * 获取交易分类名称
   */
  private getCategoryName(tx: Transaction): string {
    if (tx.type === TransactionType.Transfer) {
      return this.getT().transfer
    }
    const categories = tx.type === TransactionType.Expense
      ? DEFAULT_EXPENSE_CATEGORIES
      : DEFAULT_INCOME_CATEGORIES
    for (let i = 0; i < categories.length; i++) {
      if (categories[i].id === tx.category) {
        return categories[i].name
      }
    }
    return this.getT().other
  }

  /**
   * 获取交易分类颜色
   */
  private getCategoryColor(tx: Transaction): string {
    if (tx.type === TransactionType.Transfer) {
      return PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6'
    }
    const categories = tx.type === TransactionType.Expense
      ? DEFAULT_EXPENSE_CATEGORIES
      : DEFAULT_INCOME_CATEGORIES
    for (let i = 0; i < categories.length; i++) {
      if (categories[i].id === tx.category) {
        return categories[i].color
      }
    }
    return '#94a3b8'
  }

  /**
   * 获取平台名称
   */
  private getPlatformName(platformId: string): string {
    for (let i = 0; i < this.platforms.length; i++) {
      if (this.platforms[i].id === platformId) {
        return this.platforms[i].name
      }
    }
    return ''
  }

  /**
   * 获取平台颜色
   */
  private getPlatformColor(platformId: string): string {
    for (let i = 0; i < this.platforms.length; i++) {
      if (this.platforms[i].id === platformId) {
        return this.platforms[i].color
      }
    }
    return '#94a3b8'
  }

  /**
   * 获取钱包名称
   */
  private getWalletName(walletId: string): string {
    for (let i = 0; i < this.wallets.length; i++) {
      if (this.wallets[i].id === walletId) {
        return this.wallets[i].name
      }
    }
    return ''
  }

  /**
   * 格式化日期时间显示（如 "3月15日 14:30"）
   */
  private formatDateTimeDisplay(datetime: string): string {
    if (!datetime) {
      return ''
    }
    try {
      const date = new Date(datetime)
      const month = date.getMonth() + 1
      const day = date.getDate()
      const hours = String(date.getHours()).padStart(2, '0')
      const minutes = String(date.getMinutes()).padStart(2, '0')
      const lang = getCurrentLanguage()
      if (lang === 'zh') {
        return `${month}月${day}日 ${hours}:${minutes}`
      } else {
        return `${this.getT().months[month - 1]} ${day} ${hours}:${minutes}`
      }
    } catch (e) {
      return ''
    }
  }

  /**
   * 格式化金额
   */
  private formatAmount(tx: Transaction): string {
    const symbol = getCurrencySymbol(tx.currency)
    if (tx.type === TransactionType.Expense) {
      return `-${symbol}${tx.amount.toFixed(2)}`
    } else if (tx.type === TransactionType.Income) {
      return `+${symbol}${tx.amount.toFixed(2)}`
    } else {
      return `${symbol}${tx.amount.toFixed(2)}`
    }
  }

  /**
   * 获取金额颜色
   */
  private getAmountColor(tx: Transaction): ResourceColor {
    if (tx.type === TransactionType.Expense) {
      return ExpenseColorMap.get(this.currentStyle) ?? '#EF4444'
    } else if (tx.type === TransactionType.Income) {
      return IncomeColorMap.get(this.currentStyle) ?? '#22C55E'
    } else if (tx.type === TransactionType.Transfer) {
      return this.currentStyle === UIStyle.Cyberpunk ? '#9933FF' : '#3B82F6'
    } else {
      return PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'
    }
  }

  /**
   * 从 ISO 日期字符串提取日期键 (YYYY-MM-DD)
   */
  private getDateKey(isoStr: string): string {
    if (!isoStr) {
      return 'unknown'
    }
    try {
      const date = new Date(isoStr)
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, '0')
      const day = String(date.getDate()).padStart(2, '0')
      return `${year}-${month}-${day}`
    } catch (e) {
      return 'unknown'
    }
  }

  /**
   * 将日期键转为显示标签
   */
  private getDateLabel(dateKey: string): string {
    const today = new Date()
    const todayKey = this.getDateKey(today.toISOString())
    const yesterday = new Date(today.getTime() - 86400000)
    const yesterdayKey = this.getDateKey(yesterday.toISOString())

    if (dateKey === todayKey) {
      return this.getT().today
    }
    if (dateKey === yesterdayKey) {
      return this.getT().yesterday
    }

    try {
      const parts = dateKey.split('-')
      const month = parseInt(parts[1])
      const day = parseInt(parts[2])
      const date = new Date(dateKey)
      const lang = getCurrentLanguage()
      if (lang === 'zh') {
        return `${month}月${day}日 ${this.getT().weekdays[date.getDay()]}`
      } else {
        return `${this.getT().months[month - 1]} ${day} ${this.getT().weekdays[date.getDay()]}`
      }
    } catch (e) {
      return dateKey
    }
  }

  /**
   * 计算当日小计
   */
  private getDaySummary(txs: Transaction[]): string {
    let expense = 0
    let income = 0
    for (let i = 0; i < txs.length; i++) {
      if (txs[i].type === TransactionType.Expense) {
        expense += txs[i].amount
      } else if (txs[i].type === TransactionType.Income) {
        income += txs[i].amount
      }
    }
    const parts: string[] = []
    if (expense > 0) {
      parts.push(`${this.getT().expenseAbbr} ¥${expense.toFixed(0)}`)
    }
    if (income > 0) {
      parts.push(`${this.getT().incomeAbbr} ¥${income.toFixed(0)}`)
    }
    return parts.join('  ')
  }
}
