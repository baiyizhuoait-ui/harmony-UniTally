/**
 * TransactionHall - 交易大厅
 * 优化版：使用 @Builder 替代自定义组件，避免组件初始化阻塞
 * 顶部过滤器支持：类型 / 分类 / 钱包 / 平台（覆盖层弹窗选择器）
 * 支持搜索、点击编辑、滑动删除
 */
import { Transaction } from '../model/Transaction'
import { Wallet } from '../model/Wallet'
import { Category, DEFAULT_EXPENSE_CATEGORIES, DEFAULT_INCOME_CATEGORIES } from '../model/Category'
import { Platform, DEFAULT_PLATFORMS } from '../model/Platform'
import { TransactionType, getCurrencySymbol } from '../constants/CurrencyConst'
import { UIStyle, PageBackgroundMap, PrimaryTextColorMap, SecondaryTextColorMap, CardBackgroundMap, RadiusMap, IncomeColorMap, ExpenseColorMap, DividerColorMap, PrimaryColorMap, PrimaryForegroundMap, SecondaryBackgroundMap } from '../constants/UIStyleConst'
import { getCurrentLanguage, getTranslation } from '../constants/I18n'

// ==================== 常量 ====================
const FILTER_ALL: string = 'all'
const FILTER_EXPENSE: string = 'expense'
const FILTER_INCOME: string = 'income'
const FILTER_TRANSFER: string = 'transfer'

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

function colorWithAlpha(hexColor: string, alpha: number): string {
  if (!hexColor || hexColor.length < 7) {
    return `rgba(128, 128, 128, ${alpha})`
  }
  const r = parseInt(hexColor.substring(1, 3), 16)
  const g = parseInt(hexColor.substring(3, 5), 16)
  const b = parseInt(hexColor.substring(5, 7), 16)
  return `rgba(${r}, ${g}, ${b}, ${alpha})`
}

// ==================== TransactionHall ====================
@Component({ freezeWhenInactive: true })
export struct TransactionHall {
  @Prop transactions: Transaction[] = []
  @Prop wallets: Wallet[] = []
  @Prop platforms: Platform[] = []
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist
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

  // 覆盖层弹窗状态
  @State showTypePicker: boolean = false
  @State showCategoryPicker: boolean = false
  @State showWalletPicker: boolean = false
  @State showPlatformPicker: boolean = false

  private getT() { return getTranslation(getCurrentLanguage()) }

  // ==================== build ====================
  build() {
    Column() {
      // 标题栏
      this.TitleBar()

      // 搜索栏
      if (this.showSearch) {
        this.SearchBar()
      }

      // 过滤器
      this.FilterBar()

      // 交易列表
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
                  this.TransactionItemBuilder(tx)
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

      // 覆盖层弹窗
      if (this.showTypePicker) {
        this.TypePickerOverlay()
      }
      if (this.showCategoryPicker) {
        this.CategoryPickerOverlay()
      }
      if (this.showWalletPicker) {
        this.WalletPickerOverlay()
      }
      if (this.showPlatformPicker) {
        this.PlatformPickerOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PageBackgroundMap.get(this.currentStyle) ?? '#F5F5F7')
  }

  // ==================== 类型选择器覆盖层 ====================
  @Builder
  TypePickerOverlay() {
    Column() {
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#40000000')
        .onClick(() => {
          this.showTypePicker = false
          this.showCategoryPicker = false
          this.showWalletPicker = false
          this.showPlatformPicker = false
        })

      Column() {
        Row() {
          Text(this.getT().selectType)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
          Blank()
          Text('✕')
            .fontSize(18)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .padding(8)
            .onClick(() => { this.showTypePicker = false })
        }
        .width('100%')
        .padding({ left: 20, right: 12, top: 20, bottom: 12 })

        Column({ space: 4 }) {
          this.TypeFilterRow(FILTER_ALL)
          this.TypeFilterRow(FILTER_EXPENSE)
          this.TypeFilterRow(FILTER_INCOME)
          this.TypeFilterRow(FILTER_TRANSFER)
        }
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .width('100%')
      .borderRadius({ topLeft: 24, topRight: 24 })
      .backgroundColor(CardBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
      .padding({ bottom: 34 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  // ==================== 分类选择器覆盖层 ====================
  @Builder
  CategoryPickerOverlay() {
    Column() {
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#40000000')
        .onClick(() => {
          this.showTypePicker = false
          this.showCategoryPicker = false
          this.showWalletPicker = false
          this.showPlatformPicker = false
        })

      Column() {
        Row() {
          Text(this.getT().selectCategory)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
          Blank()
          Text('✕')
            .fontSize(18)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .padding(8)
            .onClick(() => { this.showCategoryPicker = false })
        }
        .width('100%')
        .padding({ left: 20, right: 12, top: 20, bottom: 12 })

        Scroll() {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            Row() {
              Text(this.getT().allRecords)
                .fontSize(13)
                .fontColor(this.selectedCategoryId === ''
                  ? (PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
                  : (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'))
            }
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderRadius(20)
            .backgroundColor(this.selectedCategoryId === ''
              ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
              : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.selectedCategoryId = ''
              this.showCategoryPicker = false
            })

            ForEach(this.getAllCategories(), (cat: Category) => {
              Row() {
                Text(cat.icon)
                  .fontSize(14)
                  .margin({ right: 4 })
                Text(cat.name)
                  .fontSize(13)
                  .fontColor(this.selectedCategoryId === cat.id
                    ? (PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
                    : (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'))
              }
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .borderRadius(20)
              .backgroundColor(this.selectedCategoryId === cat.id
                ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
                : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.selectedCategoryId = cat.id
                this.currentFilter = FILTER_ALL
                this.selectedWalletId = ''
                this.selectedPlatformId = ''
                this.showCategoryPicker = false
              })
            }, (cat: Category) => cat.id)
          }
          .padding({ left: 16, right: 16, bottom: 24 })
        }
        .scrollBar(BarState.Auto)
        .constraintSize({ maxHeight: 320 })
      }
      .width('100%')
      .borderRadius({ topLeft: 24, topRight: 24 })
      .backgroundColor(CardBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
      .padding({ bottom: 34 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  // ==================== 钱包选择器覆盖层 ====================
  @Builder
  WalletPickerOverlay() {
    Column() {
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#40000000')
        .onClick(() => {
          this.showTypePicker = false
          this.showCategoryPicker = false
          this.showWalletPicker = false
          this.showPlatformPicker = false
        })

      Column() {
        Row() {
          Text(this.getT().selectWallet)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
          Blank()
          Text('✕')
            .fontSize(18)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .padding(8)
            .onClick(() => { this.showWalletPicker = false })
        }
        .width('100%')
        .padding({ left: 20, right: 12, top: 20, bottom: 12 })

        Column({ space: 4 }) {
          Row() {
            Text(this.getT().allRecords)
              .fontSize(14)
              .fontColor(this.selectedWalletId === ''
                ? (PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
                : (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'))
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .borderRadius(RadiusMap.get(this.currentStyle) ?? 16)
          .backgroundColor(this.selectedWalletId === ''
            ? colorWithAlpha(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6', 0.1)
            : Color.Transparent)
          .onClick(() => {
            this.selectedWalletId = ''
            this.showWalletPicker = false
          })

          ForEach(this.wallets, (wallet: Wallet) => {
            Row() {
              Text(wallet.icon)
                .fontSize(16)
                .margin({ right: 8 })
              Text(wallet.name)
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                .layoutWeight(1)
              Text(wallet.balance.toFixed(2) + ' ' + wallet.currency)
                .fontSize(12)
                .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .borderRadius(RadiusMap.get(this.currentStyle) ?? 16)
            .backgroundColor(this.selectedWalletId === wallet.id
              ? colorWithAlpha(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6', 0.1)
              : Color.Transparent)
            .border(this.selectedWalletId === wallet.id
              ? { width: 1, color: PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6', style: BorderStyle.Solid }
              : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
            .onClick(() => {
              this.selectedWalletId = wallet.id
              this.currentFilter = FILTER_ALL
              this.selectedCategoryId = ''
              this.selectedPlatformId = ''
              this.showWalletPicker = false
            })
          }, (wallet: Wallet) => wallet.id)
        }
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .width('100%')
      .borderRadius({ topLeft: 24, topRight: 24 })
      .backgroundColor(CardBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
      .padding({ bottom: 34 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  // ==================== 平台选择器覆盖层 ====================
  @Builder
  PlatformPickerOverlay() {
    Column() {
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#40000000')
        .onClick(() => {
          this.showTypePicker = false
          this.showCategoryPicker = false
          this.showWalletPicker = false
          this.showPlatformPicker = false
        })

      Column() {
        Row() {
          Text(this.getT().selectPlatform)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
          Blank()
          Text('✕')
            .fontSize(18)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
            .padding(8)
            .onClick(() => { this.showPlatformPicker = false })
        }
        .width('100%')
        .padding({ left: 20, right: 12, top: 20, bottom: 12 })

        Column({ space: 4 }) {
          Row() {
            Text(this.getT().allRecords)
              .fontSize(14)
              .fontColor(this.selectedPlatformId === ''
                ? (PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
                : (PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'))
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
          .borderRadius(RadiusMap.get(this.currentStyle) ?? 16)
          .backgroundColor(this.selectedPlatformId === ''
            ? colorWithAlpha(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6', 0.1)
            : Color.Transparent)
          .onClick(() => {
            this.selectedPlatformId = ''
            this.showPlatformPicker = false
          })

          ForEach(this.platforms, (plat: Platform) => {
            Row() {
              Text(plat.icon)
                .fontSize(16)
                .margin({ right: 8 })
              Text(plat.name)
                .fontSize(14)
                .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .borderRadius(RadiusMap.get(this.currentStyle) ?? 16)
            .backgroundColor(this.selectedPlatformId === plat.id
              ? colorWithAlpha(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6', 0.1)
              : Color.Transparent)
            .border(this.selectedPlatformId === plat.id
              ? { width: 1, color: PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6', style: BorderStyle.Solid }
              : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
            .onClick(() => {
              this.selectedPlatformId = plat.id
              this.currentFilter = FILTER_ALL
              this.selectedCategoryId = ''
              this.selectedWalletId = ''
              this.showPlatformPicker = false
            })
          }, (plat: Platform) => plat.id)
        }
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .width('100%')
      .borderRadius({ topLeft: 24, topRight: 24 })
      .backgroundColor(CardBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
      .padding({ bottom: 34 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  // ==================== 类型过滤行 ====================
  @Builder
  TypeFilterRow(key: string) {
    Row() {
      Text(this.getTypeLabel(key))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .borderRadius(RadiusMap.get(this.currentStyle) ?? 16)
    .backgroundColor(this.currentFilter === key
      ? colorWithAlpha(PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6', 0.1)
      : Color.Transparent)
    .border(this.currentFilter === key
      ? { width: 1, color: PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6', style: BorderStyle.Solid }
      : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
    .onClick(() => {
      this.currentFilter = key
      this.selectedCategoryId = ''
      this.selectedWalletId = ''
      this.selectedPlatformId = ''
      this.showTypePicker = false
    })
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

      Text(this.showSearch ? '✕' : '🔍')
        .fontSize(18)
        .padding(8)
        .onClick(() => {
          if (this.showSearch) {
            this.showSearch = false
            this.searchText = ''
          } else {
            this.showSearch = true
          }
        })
    }
    .width('100%')
    .padding({ left: 20, right: 12, top: 16, bottom: 8 })
  }

  // ==================== 搜索栏 ====================
  @Builder
  SearchBar() {
    Row() {
      TextInput({ text: $$this.searchText, placeholder: this.getT().searchPlaceholder })
        .type(InputType.Normal)
        .height(40)
        .layoutWeight(1)
        .borderRadius(20)
        .backgroundColor(SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5')
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
        Text('⚙')
          .fontSize(12)
          .margin({ right: 4 })
        Text(this.getTypeLabel(this.currentFilter))
          .fontSize(13)
          .fontColor(this.currentFilter !== FILTER_ALL
            ? (PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
            : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'))
        Text('▾')
          .fontSize(12)
          .fontColor(this.currentFilter !== FILTER_ALL
            ? (PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
            : (SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'))
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(20)
      .backgroundColor(this.currentFilter !== FILTER_ALL
        ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
        : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
      .border(this.currentFilter !== FILTER_ALL
        ? { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
        : { width: 1, color: DividerColorMap.get(this.currentStyle) ?? '#E0E0E0', style: BorderStyle.Solid })
      .margin({ right: 8, bottom: 8 })
      .onClick(() => { this.showTypePicker = true })

      // 分类过滤按钮
      Row() {
        if (this.selectedCategoryId !== '') {
          Text(this.getCategoryById(this.selectedCategoryId).icon)
            .fontSize(12)
            .margin({ right: 4 })
          Text(this.getCategoryById(this.selectedCategoryId).name)
            .fontSize(13)
            .fontColor(PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
        } else {
          Text(this.getT().selectCategory)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          Text('▾')
            .fontSize(12)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
        }
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(20)
      .backgroundColor(this.selectedCategoryId !== ''
        ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
        : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
      .border(this.selectedCategoryId !== ''
        ? { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
        : { width: 1, color: DividerColorMap.get(this.currentStyle) ?? '#E0E0E0', style: BorderStyle.Solid })
      .margin({ right: 8, bottom: 8 })
      .onClick(() => { this.showCategoryPicker = true })

      // 钱包过滤按钮
      Row() {
        if (this.selectedWalletId !== '') {
          Text(this.getWalletById(this.selectedWalletId).icon)
            .fontSize(12)
            .margin({ right: 4 })
          Text(this.getWalletById(this.selectedWalletId).name)
            .fontSize(13)
            .fontColor(PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
        } else {
          Text(this.getT().selectWallet)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          Text('▾')
            .fontSize(12)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
        }
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(20)
      .backgroundColor(this.selectedWalletId !== ''
        ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
        : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
      .border(this.selectedWalletId !== ''
        ? { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
        : { width: 1, color: DividerColorMap.get(this.currentStyle) ?? '#E0E0E0', style: BorderStyle.Solid })
      .margin({ right: 8, bottom: 8 })
      .onClick(() => { this.showWalletPicker = true })

      // 平台过滤按钮
      Row() {
        if (this.selectedPlatformId !== '') {
          Text(this.getPlatformById(this.selectedPlatformId).icon)
            .fontSize(12)
            .margin({ right: 4 })
          Text(this.getPlatformById(this.selectedPlatformId).name)
            .fontSize(13)
            .fontColor(PrimaryForegroundMap.get(this.currentStyle) ?? '#FFFFFF')
        } else {
          Text(this.getT().selectPlatform)
            .fontSize(13)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
          Text('▾')
            .fontSize(12)
            .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
        }
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(20)
      .backgroundColor(this.selectedPlatformId !== ''
        ? (PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6')
        : (SecondaryBackgroundMap.get(this.currentStyle) ?? '#F5F5F5'))
      .border(this.selectedPlatformId !== ''
        ? { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
        : { width: 1, color: DividerColorMap.get(this.currentStyle) ?? '#E0E0E0', style: BorderStyle.Solid })
      .margin({ right: 8, bottom: 8 })
      .onClick(() => { this.showPlatformPicker = true })
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
      Text(this.getDaySummary(txs))
        .fontSize(12)
        .fontColor(SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93')
    }
    .width('100%')
    .padding({ left: 4, right: 4, top: 12, bottom: 6 })
  }

  // ==================== 交易项（用 @Builder 替代自定义组件） ====================
  @Builder
  TransactionItemBuilder(tx: Transaction) {
    Column() {
      Row() {
        // 分类图标（带颜色背景圆）
        Column() {
          Text(this.getCategoryIcon(tx))
            .fontSize(20)
        }
        .width(40)
        .height(40)
        .borderRadius(16)
        .backgroundColor(colorWithAlpha(this.getCategoryColor(tx), 0.1))
        .justifyContent(FlexAlign.Center)
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
      .padding(14)
      .backgroundColor(CardBackgroundMap.get(this.currentStyle) ?? '#FFFFFF')
      .borderRadius(RadiusMap.get(this.currentStyle) ?? 16)
    }
    .onClick(() => { this.onEditTransaction(tx) })
  }

  // ==================== 滑动删除按钮 ====================
  @Builder
  DeleteSwipeAction(txId: string) {
    Row() {
      Column() {
        Text('🗑')
          .fontSize(16)
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
    .onClick(() => { this.onDeleteTransaction(txId) })
  }

  // ==================== 数据过滤与分组 ====================

  private getFilteredList(): Transaction[] {
    let list = this.transactions
    if (this.currentFilter !== FILTER_ALL) {
      const filterStr: string = this.currentFilter
      list = list.filter((tx: Transaction) => {
        if (filterStr === FILTER_TRANSFER) { return tx.type === TransactionType.Transfer }
        return tx.type === filterStr
      })
    }
    if (this.selectedCategoryId !== '' || this.selectedWalletId !== '' || this.selectedPlatformId !== '') {
      list = list.filter((tx: Transaction) => tx.type !== TransactionType.Transfer)
    }
    if (this.selectedCategoryId !== '') {
      const catId = this.selectedCategoryId
      list = list.filter((tx: Transaction) => tx.category === catId)
    }
    if (this.selectedWalletId !== '') {
      const walletId = this.selectedWalletId
      list = list.filter((tx: Transaction) => tx.walletId === walletId)
    }
    if (this.selectedPlatformId !== '') {
      const platId = this.selectedPlatformId
      list = list.filter((tx: Transaction) => tx.platformId === platId)
    }
    if (this.searchText !== '') {
      const keyword = this.searchText.toLowerCase()
      list = list.filter((tx: Transaction) => {
        const noteMatch = tx.note && tx.note.toLowerCase().includes(keyword)
        const catMatch = this.getCategoryName(tx).toLowerCase().includes(keyword)
        const walletMatch = this.getWalletName(tx.walletId).toLowerCase().includes(keyword)
        return noteMatch || catMatch || walletMatch
      })
    }
    list.sort((a: Transaction, b: Transaction) => {
      const timeDiff = new Date(b.datetime).getTime() - new Date(a.datetime).getTime()
      if (timeDiff !== 0) return timeDiff
      return b.createdAt - a.createdAt
    })
    return list
  }

  private getDateGroups(): DateGroup[] {
    const filtered = this.getFilteredList()
    if (filtered.length === 0) { return [] }
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
      if (group !== undefined) { group.push(tx) }
    }
    const groups: DateGroup[] = []
    for (let i = 0; i < dateOrder.length; i++) {
      const key = dateOrder[i]
      const groupList = groupMap.get(key)
      if (groupList !== undefined) {
        groups.push(new DateGroup(key, this.getDateLabel(key), groupList))
      }
    }
    return groups
  }

  // ==================== 辅助方法 ====================

  private getTypeLabel(key: string): string {
    const t = this.getT()
    switch (key) {
      case FILTER_ALL: return t.allRecords
      case FILTER_EXPENSE: return t.expenseOnly
      case FILTER_INCOME: return t.incomeOnly
      case FILTER_TRANSFER: return t.transferOnly
      default: return key
    }
  }

  private getAllCategories(): Category[] {
    const result: Category[] = []
    for (let i = 0; i < DEFAULT_EXPENSE_CATEGORIES.length; i++) { result.push(DEFAULT_EXPENSE_CATEGORIES[i]) }
    for (let i = 0; i < DEFAULT_INCOME_CATEGORIES.length; i++) { result.push(DEFAULT_INCOME_CATEGORIES[i]) }
    return result
  }

  private getCategoryById(categoryId: string): Category {
    for (let i = 0; i < DEFAULT_EXPENSE_CATEGORIES.length; i++) {
      if (DEFAULT_EXPENSE_CATEGORIES[i].id === categoryId) { return DEFAULT_EXPENSE_CATEGORIES[i] }
    }
    for (let i = 0; i < DEFAULT_INCOME_CATEGORIES.length; i++) {
      if (DEFAULT_INCOME_CATEGORIES[i].id === categoryId) { return DEFAULT_INCOME_CATEGORIES[i] }
    }
    return new Category('', '', '', '#94a3b8', 0)
  }

  private getWalletById(walletId: string): Wallet {
    for (let i = 0; i < this.wallets.length; i++) {
      if (this.wallets[i].id === walletId) { return this.wallets[i] }
    }
    return new Wallet('', '', '#94a3b8', '💰', 'CNY', 0)
  }

  private getPlatformById(platformId: string): Platform {
    for (let i = 0; i < this.platforms.length; i++) {
      if (this.platforms[i].id === platformId) { return this.platforms[i] }
    }
    return new Platform('', '', '', '#94a3b8', 0)
  }

  private getCategoryIcon(tx: Transaction): string {
    if (tx.type === TransactionType.Transfer) { return '🔄' }
    const categories = tx.type === TransactionType.Expense ? DEFAULT_EXPENSE_CATEGORIES : DEFAULT_INCOME_CATEGORIES
    for (let i = 0; i < categories.length; i++) {
      if (categories[i].id === tx.category) { return categories[i].icon }
    }
    return '📌'
  }

  private getCategoryName(tx: Transaction): string {
    if (tx.type === TransactionType.Transfer) { return this.getT().transfer }
    const categories = tx.type === TransactionType.Expense ? DEFAULT_EXPENSE_CATEGORIES : DEFAULT_INCOME_CATEGORIES
    for (let i = 0; i < categories.length; i++) {
      if (categories[i].id === tx.category) { return categories[i].name }
    }
    return this.getT().other
  }

  private getCategoryColor(tx: Transaction): string {
    if (tx.type === TransactionType.Transfer) { return PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6' }
    const categories = tx.type === TransactionType.Expense ? DEFAULT_EXPENSE_CATEGORIES : DEFAULT_INCOME_CATEGORIES
    for (let i = 0; i < categories.length; i++) {
      if (categories[i].id === tx.category) { return categories[i].color }
    }
    return '#94a3b8'
  }

  private getPlatformName(platformId: string): string {
    for (let i = 0; i < this.platforms.length; i++) {
      if (this.platforms[i].id === platformId) { return this.platforms[i].name }
    }
    return ''
  }

  private getPlatformColor(platformId: string): string {
    for (let i = 0; i < this.platforms.length; i++) {
      if (this.platforms[i].id === platformId) { return this.platforms[i].color }
    }
    return '#94a3b8'
  }

  private getWalletName(walletId: string): string {
    for (let i = 0; i < this.wallets.length; i++) {
      if (this.wallets[i].id === walletId) { return this.wallets[i].name }
    }
    return ''
  }

  private formatDateTimeDisplay(datetime: string): string {
    if (!datetime) { return '' }
    try {
      const date = new Date(datetime)
      const month = date.getMonth() + 1
      const day = date.getDate()
      const hours = String(date.getHours()).padStart(2, '0')
      const minutes = String(date.getMinutes()).padStart(2, '0')
      const lang = getCurrentLanguage()
      if (lang === 'zh') { return `${month}月${day}日 ${hours}:${minutes}` }
      else { return `${this.getT().months[month - 1]} ${day} ${hours}:${minutes}` }
    } catch (e) { return '' }
  }

  private formatAmount(tx: Transaction): string {
    const symbol = getCurrencySymbol(tx.currency)
    if (tx.type === TransactionType.Expense) { return `-${symbol}${tx.amount.toFixed(2)}` }
    else if (tx.type === TransactionType.Income) { return `+${symbol}${tx.amount.toFixed(2)}` }
    else { return `${symbol}${tx.amount.toFixed(2)}` }
  }

  private getAmountColor(tx: Transaction): ResourceColor {
    if (tx.type === TransactionType.Expense) { return ExpenseColorMap.get(this.currentStyle) ?? '#EF4444' }
    else if (tx.type === TransactionType.Income) { return IncomeColorMap.get(this.currentStyle) ?? '#22C55E' }
    else if (tx.type === TransactionType.Transfer) { return this.currentStyle === UIStyle.Cyberpunk ? '#9933FF' : '#3B82F6' }
    else { return PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E' }
  }

  private getDateKey(isoStr: string): string {
    if (!isoStr) { return 'unknown' }
    try {
      const date = new Date(isoStr)
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
    } catch (e) { return 'unknown' }
  }

  private getDateLabel(dateKey: string): string {
    const today = new Date()
    const todayKey = this.getDateKey(today.toISOString())
    const yesterday = new Date(today.getTime() - 86400000)
    const yesterdayKey = this.getDateKey(yesterday.toISOString())
    if (dateKey === todayKey) { return this.getT().today }
    if (dateKey === yesterdayKey) { return this.getT().yesterday }
    try {
      const parts = dateKey.split('-')
      const month = parseInt(parts[1])
      const day = parseInt(parts[2])
      const date = new Date(dateKey)
      const lang = getCurrentLanguage()
      if (lang === 'zh') { return `${month}月${day}日 ${this.getT().weekdays[date.getDay()]}` }
      else { return `${this.getT().months[month - 1]} ${day} ${this.getT().weekdays[date.getDay()]}` }
    } catch (e) { return dateKey }
  }

  private getDaySummary(txs: Transaction[]): string {
    let expense = 0
    let income = 0
    for (let i = 0; i < txs.length; i++) {
      if (txs[i].type === TransactionType.Expense) { expense += txs[i].amount }
      else if (txs[i].type === TransactionType.Income) { income += txs[i].amount }
    }
    const parts: string[] = []
    if (expense > 0) { parts.push(`${this.getT().expenseAbbr} ¥${expense.toFixed(0)}`) }
    if (income > 0) { parts.push(`${this.getT().incomeAbbr} ¥${income.toFixed(0)}`) }
    return parts.join('  ')
  }
}
