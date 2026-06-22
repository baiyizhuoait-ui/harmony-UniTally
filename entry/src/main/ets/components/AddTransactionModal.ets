﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿/**
 * AddTransactionModal - 核心记账弹窗
 * 支持支出/收入/转账三个独立 Tab
 * 转账 Tab 实现跨币种动态表单：同币种单金额输入，跨币种双金额输入
 * 转账记录 type 严格标记为 'transfer'，确保后续统计中被剔除
 * 复用 UniCard / UniButton / UniInput 组件
 * 对齐原版 React：平台选择器、货币选择器、彩色标签页、转账箭头、时间显示
 */
import { UniCard } from './UniCard'
import { UniButton } from './UniButton'
import { UniInput } from './UniInput'
import { Transaction, createTransactionFromJson } from '../model/Transaction'
import { Wallet } from '../model/Wallet'
import { Platform } from '../model/Platform'
import { Category, getDefaultExpenseCategories, getDefaultIncomeCategories } from '../model/Category'
import { TransactionType, WalletType, getCurrencySymbol, getCurrencyList, CurrencyInfo, getWalletTypeLabel, WalletTypeIcon } from '../constants/CurrencyConst'
import {
  UIStyle, PrimaryTextColorMap, SecondaryTextColorMap, PageBackgroundMap,
  ExpenseColorMap, IncomeColorMap, PrimaryColorMap,
  SecondaryBackgroundMap, DividerColorMap
} from '../constants/UIStyleConst'
import { getCurrentLanguage, getTranslation } from '../constants/I18n'
import { AppIcon } from '../components/AppIcon'

import photoAccessHelper from '@ohos.file.photoAccessHelper'

@Component
export struct AddTransactionModal {
  // 关闭回调（bindSheet 模式下由父组件传入）
  onClose: () => void = () => {
  }

  // ==================== 全局风格监听 ====================
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist

  // ==================== Tab 状态 ====================
  @State currentTabIndex: number = 0

  // ==================== 支出/收入表单 ====================
  @State amountText: string = ''
  @State noteText: string = ''
  @State selectedDate: string = ''
  @State selectedCategoryId: string = ''
  @State selectedWalletId: string = ''
  @State selectedPlatformId: string = ''
  @State selectedCurrency: string = 'CNY'

  // ==================== 转账表单 ====================
  @State fromWalletId: string = ''
  @State toWalletId: string = ''
  @State fromAmountText: string = ''
  @State toAmountText: string = ''
  @State transferNoteText: string = ''
  @State transferDate: string = ''

  // ==================== 图片相关 ====================
  @State selectedImageUri: string = ''
  @State transferImageUri: string = ''

  // ==================== 外部数据 ====================
  @State walletList: Wallet[] = []
  @State platformList: Platform[] = []

  // 编辑模式：通过 AppStorage 传入编辑交易 ID
  // 在 aboutToAppear 中读取并预填充表单
  @State editTransactionId: string = ''
  @State editTransaction: Transaction | null = null

  // 外部交易列表（编辑时用于查找原始交易）
  @State transactionList: Transaction[] = []

  // 回调：保存交易记录
  onSave: (transaction: Transaction) => void = () => {
  }

  // ==================== i18n 翻译 ====================
  private getT() {
    return getTranslation(getCurrentLanguage())
  }

  // ==================== 生命周期 ====================
  aboutToAppear(): void {
    // 从 AppStorage 读取编辑交易 ID
    const editId = AppStorage.get<string>('editTransactionId') ?? ''
    if (editId !== '' && this.transactionList.length > 0) {
      // 从交易列表中查找要编辑的交易
      for (let i = 0; i < this.transactionList.length; i++) {
        if (this.transactionList[i].id === editId) {
          this.editTransaction = this.transactionList[i]
          this.prefillForm(this.editTransaction!)
          break
        }
      }
      // 清除 AppStorage 中的编辑 ID，避免下次打开时误读
      AppStorage.setOrCreate('editTransactionId', '')
    } else if (editId !== '' && this.walletList.length > 0) {
      // 备用：如果没传 transactionList，尝试从 AppStorage 读取序列化的交易数据
      const editTxJson = AppStorage.get<string>('editTransactionJson') ?? ''
      if (editTxJson !== '') {
        try {
          this.editTransaction = createTransactionFromJson(JSON.parse(editTxJson) as Record<string, Object>)
          this.prefillForm(this.editTransaction!)
        } catch (e) {
          console.error('Failed to parse editTransactionJson:', e)
        }
        AppStorage.setOrCreate('editTransactionJson', '')
      }
      AppStorage.setOrCreate('editTransactionId', '')
    } else {
      // 新增模式：设置默认值
      if (this.walletList.length > 0 && this.selectedWalletId === '') {
        this.selectedWalletId = this.walletList[0].id
      }
      if (this.walletList.length > 0 && this.fromWalletId === '') {
        this.fromWalletId = this.walletList[0].id
      }
      if (this.walletList.length > 1 && this.toWalletId === '') {
        this.toWalletId = this.walletList[1].id
      } else if (this.walletList.length === 1 && this.toWalletId === '') {
        this.toWalletId = this.walletList[0].id
      }
      if (this.selectedDate === '') {
        this.selectedDate = this.getNowISO()
      }
      if (this.transferDate === '') {
        this.transferDate = this.getNowISO()
      }
      // 默认选中第一个平台
      if (this.platformList.length > 0 && this.selectedPlatformId === '') {
        this.selectedPlatformId = this.platformList[0].id
      }
    }
  }

  /**
   * 预填充表单（编辑模式）
   */
  private prefillForm(tx: Transaction): void {
    if (tx.type === TransactionType.Transfer) {
      this.currentTabIndex = 2
      this.fromWalletId = tx.fromWalletId || tx.walletId
      this.toWalletId = tx.toWalletId || ''
      this.fromAmountText = tx.fromAmount ? tx.fromAmount.toString() : tx.amount.toString()
      this.toAmountText = tx.toAmount ? tx.toAmount.toString() : tx.amount.toString()
      this.transferNoteText = tx.note || ''
      this.transferDate = tx.datetime || this.getNowISO()
      this.transferImageUri = tx.imageUri || ''
    } else {
      this.currentTabIndex = tx.type === TransactionType.Income ? 1 : 0
      this.amountText = tx.amount.toString()
      this.noteText = tx.note || ''
      this.selectedWalletId = tx.walletId
      this.selectedCategoryId = tx.category || ''
      this.selectedDate = tx.datetime || this.getNowISO()
      this.selectedImageUri = tx.imageUri || ''
      this.selectedCurrency = tx.currency || 'CNY'
      this.selectedPlatformId = tx.platformId || ''
    }
  }

  /**
   * 判断是否为编辑模式
   */
  private isEditMode(): boolean {
    return this.editTransaction !== null
  }

  // ==================== 钱包选择辅助 ====================

  private getWalletsByType(wType: WalletType): Wallet[] {
    const result: Wallet[] = []
    for (let i = 0; i < this.walletList.length; i++) {
      if (this.walletList[i].type === wType) {
        result.push(this.walletList[i])
      }
    }
    return result
  }

  private getWalletTypeLabel(wType: WalletType): string {
    switch (wType) {
      case WalletType.Cash:
        return this.getT().cashWallet
      case WalletType.Savings:
        return this.getT().savingsAccount
      case WalletType.Credit:
        return this.getT().creditCard
      case WalletType.EWallet:
        return this.getT().ewalletAccount
      default:
        return getWalletTypeLabel(wType)
    }
  }

  private isWalletSelected(target: string, walletId: string): boolean {
    switch (target) {
      case 'expense':
      case 'income':
        return this.selectedWalletId === walletId
      case 'from':
        return this.fromWalletId === walletId
      case 'to':
        return this.toWalletId === walletId
      default:
        return false
    }
  }

  private selectWallet(target: string, walletId: string): void {
    switch (target) {
      case 'expense':
      case 'income':
        this.selectedWalletId = walletId
        break
      case 'from':
        this.fromWalletId = walletId
        break
      case 'to':
        this.toWalletId = walletId
        break
      default:
        break
    }
  }

  private isCrossCurrency(): boolean {
    const fromWallet = this.findWallet(this.fromWalletId)
    const toWallet = this.findWallet(this.toWalletId)
    if (!fromWallet || !toWallet) {
      return false
    }
    return fromWallet.currency !== toWallet.currency
  }

  private findWallet(id: string): Wallet | null {
    for (let i = 0; i < this.walletList.length; i++) {
      if (this.walletList[i].id === id) {
        return this.walletList[i]
      }
    }
    return null
  }

  private getFromWalletSymbol(): string {
    const wallet = this.findWallet(this.fromWalletId)
    return wallet ? getCurrencySymbol(wallet.currency) : '¥'
  }

  private getToWalletSymbol(): string {
    const wallet = this.findWallet(this.toWalletId)
    return wallet ? getCurrencySymbol(wallet.currency) : '$'
  }

  private getFromWalletCurrency(): string {
    const wallet = this.findWallet(this.fromWalletId)
    return wallet ? wallet.currency : 'CNY'
  }

  private getToWalletCurrency(): string {
    const wallet = this.findWallet(this.toWalletId)
    return wallet ? wallet.currency : 'CNY'
  }

  private getNowISO(): string {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, '0')
    const day = String(now.getDate()).padStart(2, '0')
    const hours = String(now.getHours()).padStart(2, '0')
    const minutes = String(now.getMinutes()).padStart(2, '0')
    return `${year}-${month}-${day}T${hours}:${minutes}:00.000Z`
  }

  private formatDateTimeByTarget(target: string): string {
    const isoStr = target === 'transfer' ? this.transferDate : this.selectedDate
    if (!isoStr || isoStr === '') {
      return this.getT().now
    }
    const date = new Date(isoStr)
    const year = date.getFullYear()
    const month = date.getMonth() + 1
    const day = date.getDate()
    const hours = String(date.getHours()).padStart(2, '0')
    const minutes = String(date.getMinutes()).padStart(2, '0')
    const today = new Date()
    if (year === today.getFullYear() && date.getMonth() === today.getMonth() &&
      date.getDate() === today.getDate()) {
      return `${this.getT().todayTime} ${hours}:${minutes}`
    }
    return `${this.getT().monthDayTime.replace('{m}', month.toString()).replace('{d}', day.toString())} ${hours}:${minutes}`
  }

  private showDatePicker(target: string): void {
    const currentDateStr = target === 'transfer' ? this.transferDate : this.selectedDate
    const selected = currentDateStr ? new Date(currentDateStr) : new Date()
    try {
      this.getUIContext().showDatePickerDialog({
        selected: selected,
        onAccept: (value: DatePickerResult) => {
          const year = value.year ?? selected.getFullYear()
          const month = (value.month ?? (selected.getMonth() - 1)) + 1
          const day = value.day ?? selected.getDate()
          const monthStr = String(month).padStart(2, '0')
          const dayStr = String(day).padStart(2, '0')
          const hours = String(selected.getHours()).padStart(2, '0')
          const minutes = String(selected.getMinutes()).padStart(2, '0')
          const newDate = `${year}-${monthStr}-${dayStr}T${hours}:${minutes}:00.000Z`
          if (target === 'transfer') {
            this.transferDate = newDate
          } else {
            this.selectedDate = newDate
          }
        }
      })
    } catch (e) {
      console.error('DatePickerDialog.show failed:', e)
    }
  }

  private resetForm(): void {
    this.amountText = ''
    this.noteText = ''
    this.selectedCategoryId = ''
    this.fromAmountText = ''
    this.toAmountText = ''
    this.transferNoteText = ''
    this.selectedImageUri = ''
    this.transferImageUri = ''
    this.selectedWalletId = ''
    this.selectedPlatformId = ''
    this.selectedCurrency = 'CNY'
    this.fromWalletId = ''
    this.toWalletId = ''
    this.selectedDate = ''
    this.transferDate = ''
    this.editTransaction = null
    this.editTransactionId = ''
  }

  private async pickImage(target: string): Promise<void> {
    try {
      const photoPicker = new photoAccessHelper.PhotoViewPicker()
      const photoSelectOptions: photoAccessHelper.PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      }

      const photoSelectResult = await photoPicker.select(photoSelectOptions)
      if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        const uri = photoSelectResult.photoUris[0]
        if (target === 'transfer') {
          this.transferImageUri = uri
        } else {
          this.selectedImageUri = uri
        }
        try {
          this.getUIContext().getPromptAction().showToast({ message: this.getT().imageAdded })
        } catch (e) {
          console.error('showToast failed:', e)
        }
      }
    } catch (error) {
      console.error('Image pick failed:', error)
      try {
        this.getUIContext().getPromptAction().showToast({ message: this.getT().addImage })
      } catch (e) {
        console.error('showToast failed:', e)
      }
    }
  }

  private getPrimaryTextColor(): ResourceColor {
    return PrimaryTextColorMap.get(this.currentStyle) ?? '#1A1A2E'
  }

  private getSecondaryTextColor(): ResourceColor {
    return SecondaryTextColorMap.get(this.currentStyle) ?? '#8E8E93'
  }

  private getDialogBackground(): ResourceColor {
    return PageBackgroundMap.get(this.currentStyle) ?? '#F5F5F7'
  }

  private getExpenseColor(): ResourceColor {
    return ExpenseColorMap.get(this.currentStyle) ?? '#EF4444'
  }

  private getIncomeColor(): ResourceColor {
    return IncomeColorMap.get(this.currentStyle) ?? '#22C55E'
  }

  private getPrimaryColor(): ResourceColor {
    return PrimaryColorMap.get(this.currentStyle) ?? '#3B82F6'
  }

  private getDialogRadius(): number {
    switch (this.currentStyle) {
      case UIStyle.Minimalist:
        return 20
      case UIStyle.Neumorphism:
        return 24
      case UIStyle.Brutalism:
        return 0
      case UIStyle.Cyberpunk:
        return 8
      default:
        return 20
    }
  }

  private getChipBackground(): ResourceColor {
    return SecondaryBackgroundMap.get(this.currentStyle) ?? '#F0F0F5'
  }

  private getDividerColor(): ResourceColor {
    return DividerColorMap.get(this.currentStyle) ?? '#E0E0E0'
  }

  private getButtonFontColor(): ResourceColor {
    switch (this.currentStyle) {
      case UIStyle.Minimalist:
        return Color.White
      case UIStyle.Neumorphism:
        return '#5A6A7A'
      case UIStyle.Brutalism:
        return '#000000'
      case UIStyle.Cyberpunk:
        return '#00FFFF'
      default:
        return Color.White
    }
  }

  // ==================== build 方法 ====================
  build() {
    Column() {
      // ---- 顶部标题栏 ----
      this.HeaderBar()

      // ---- 自定义彩色标签页 ----
      this.ColoredTabBar()

      // ---- 内容区域 ----
      if (this.currentTabIndex === 0) {
        Scroll() {
          this.ExpenseIncomeForm(getDefaultExpenseCategories(), TransactionType.Expense)
        }.scrollBar(BarState.Off).layoutWeight(1)
      } else if (this.currentTabIndex === 1) {
        Scroll() {
          this.ExpenseIncomeForm(getDefaultIncomeCategories(), TransactionType.Income)
        }.scrollBar(BarState.Off).layoutWeight(1)
      } else {
        Scroll() {
          this.TransferForm()
        }.scrollBar(BarState.Off).layoutWeight(1)
      }
    }
    .width('100%')
    .constraintSize({ maxHeight: '85%' })
    .backgroundColor(this.getDialogBackground())
    .borderRadius({ topLeft: this.getDialogRadius(), topRight: this.getDialogRadius() })
  }

  // ==================== 顶部标题栏 ====================
  @Builder
  HeaderBar() {
    Row() {
      Text(this.isEditMode() ? this.getT().editTransaction : this.getT().addTransaction)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getPrimaryTextColor())

      Blank()

      // 货币选择器（仅支出/收入时显示）
      if (this.currentTabIndex !== 2) {
        this.CurrencyChips()
      }

      AppIcon({ icon: 'x', fontSize: 20, fontColor: this.getSecondaryTextColor() })
        .padding(8)
        .margin({ left: 8 })
        .onClick(() => {
          this.onClose()
        })
    }
    .width('100%')
    .padding({ left: 20, right: 12, top: 16, bottom: 8 })
  }

  // ==================== 彩色标签页 ====================
  @Builder
  ColoredTabBar() {
    Row({ space: 8 }) {
      // 支出 Tab
      Text(this.getT().expense)
        .fontSize(14)
        .fontWeight(this.currentTabIndex === 0 ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTabIndex === 0 ? '#FFFFFF' : this.getSecondaryTextColor())
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 20)
        .backgroundColor(this.currentTabIndex === 0 ? this.getExpenseColor() : Color.Transparent)
        .onClick(() => {
          this.currentTabIndex = 0
        })

      // 收入 Tab
      Text(this.getT().income)
        .fontSize(14)
        .fontWeight(this.currentTabIndex === 1 ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTabIndex === 1 ? '#FFFFFF' : this.getSecondaryTextColor())
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 20)
        .backgroundColor(this.currentTabIndex === 1 ? this.getIncomeColor() : Color.Transparent)
        .onClick(() => {
          this.currentTabIndex = 1
        })

      // 转账 Tab
      Text(this.getT().transfer)
        .fontSize(14)
        .fontWeight(this.currentTabIndex === 2 ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTabIndex === 2 ? '#FFFFFF' : this.getSecondaryTextColor())
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 20)
        .backgroundColor(this.currentTabIndex === 2 ? this.getPrimaryColor() : Color.Transparent)
        .onClick(() => {
          this.currentTabIndex = 2
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 12 })
  }

  // ==================== 货币选择芯片 ====================
  @Builder
  CurrencyChips() {
    Scroll() {
      Row({ space: 6 }) {
        ForEach(getCurrencyList(), (currencyInfo: CurrencyInfo) => {
          Text(currencyInfo.code)
            .fontSize(11)
            .fontWeight(this.selectedCurrency === currencyInfo.code ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedCurrency === currencyInfo.code ? '#FFFFFF' : this.getSecondaryTextColor())
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 12)
            .backgroundColor(this.selectedCurrency === currencyInfo.code
              ? this.getPrimaryColor()
              : this.getChipBackground())
            .border(this.selectedCurrency === currencyInfo.code
              ? { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
              : { width: 1, color: this.getDividerColor(), style: BorderStyle.Solid })
            .onClick(() => {
              this.selectedCurrency = currencyInfo.code
            })
        }, (currencyInfo: CurrencyInfo) => currencyInfo.code)
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .constraintSize({ maxWidth: 180 })
  }

  // ==================== 支出/收入表单（共享 Builder） ====================
  @Builder
  ExpenseIncomeForm(categories: Category[], type: TransactionType) {
    Column() {
      // ---- 金额输入区 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Text(type === TransactionType.Expense ? this.getT().expenseAmount : this.getT().incomeAmount)
            .fontSize(13)
            .fontColor(this.getSecondaryTextColor())
            .margin({ bottom: 8 })

          Row() {
            Text(getCurrencySymbol(this.selectedCurrency))
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getPrimaryTextColor())
              .margin({ right: 8 })

            UniInput({
              textValue: $amountText,
              placeholder: '0.00',
              inputType: InputType.NUMBER_DECIMAL,
              heightValue: 56
            })
          }
          .width('100%')
        }
      }

      // ---- 钱包选择 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Text(this.getT().selectWalletLabel)
            .fontSize(13)
            .fontColor(this.getSecondaryTextColor())
            .margin({ bottom: 8 })

          this.GroupedWalletSelector('expense')
        }
        .alignItems(HorizontalAlign.Start)
      }

      // ---- 平台选择 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Text(this.getT().selectPlatformLabel)
            .fontSize(13)
            .fontColor(this.getSecondaryTextColor())
            .margin({ bottom: 8 })

          this.PlatformChipRow()
        }
        .alignItems(HorizontalAlign.Start)
      }

      // ---- 分类选择（仅支出时显示，收入自动设为 'income'） ----
      if (type === TransactionType.Expense) {
        UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
          Column() {
            Text(this.getT().selectCategoryLabel)
              .fontSize(13)
              .fontColor(this.getSecondaryTextColor())
              .margin({ bottom: 8 })

            this.CategoryGrid(categories)
          }
          .alignItems(HorizontalAlign.Start)
        }
      }

      // ---- 日期时间选择 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        this.DateRow('expense')
      }

      // ---- 备注 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Text(this.getT().note)
            .fontSize(13)
            .fontColor(this.getSecondaryTextColor())
            .margin({ bottom: 8 })

          UniInput({
            textValue: $noteText,
            placeholder: this.getT().addNote,
            inputType: InputType.Normal,
            heightValue: 44
          })
        }
      }

      // ---- 图片凭证 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Text(this.getT().addImage)
            .fontSize(13)
            .fontColor(this.getSecondaryTextColor())
            .margin({ bottom: 8 })

          if (this.selectedImageUri === '') {
            Row() {
              AppIcon({ icon: 'image', fontSize: 18 })
                .margin({ right: 8 })

              Text(this.getT().addImage)
                .fontSize(14)
                .fontColor(this.getPrimaryTextColor())
            }
            .width('100%')
            .height(60)
            .justifyContent(FlexAlign.Center)
            .borderRadius(8)
            .border({ width: 1, color: this.getDividerColor(), style: BorderStyle.Dashed })
            .onClick(() => {
              this.pickImage('expense')
            })
          } else {
            Row() {
              Image(this.selectedImageUri)
                .width(60)
                .height(60)
                .objectFit(ImageFit.Cover)
                .borderRadius(8)
                .margin({ right: 12 })

              Column() {
                Text(this.getT().imageAdded)
                  .fontSize(14)
                  .fontColor(this.getPrimaryTextColor())

                Text(this.getT().clickToChange)
                  .fontSize(12)
                  .fontColor(this.getSecondaryTextColor())
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              AppIcon({ icon: 'x', fontSize: 18, fontColor: this.getSecondaryTextColor() })
                .onClick(() => {
                  this.selectedImageUri = ''
                })
            }
            .width('100%')
            .onClick(() => {
              this.pickImage('expense')
            })
          }
        }
        .alignItems(HorizontalAlign.Start)
      }

      // ---- 保存按钮 ----
      UniButton({
        marginValue: { left: 16, right: 16, top: 20, bottom: 24 },
        onClickHandler: () => {
          this.saveExpenseOrIncome(type)
        }
      }) {
        Text(this.getT().save)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getButtonFontColor())
      }
    }
  }

  // ==================== 转账表单 ====================
  @Builder
  TransferForm() {
    Column() {
      // 钱包不足提示
      if (this.walletList.length < 2) {
        UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
          Text(this.getT().needTwoWallets)
            .fontSize(14)
            .fontColor(this.getSecondaryTextColor())
        }
      }

      // ---- 转出钱包 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Text(this.getT().fromWallet)
            .fontSize(13)
            .fontColor(this.getSecondaryTextColor())
            .margin({ bottom: 8 })

          this.GroupedWalletSelector('from')
        }
        .alignItems(HorizontalAlign.Start)
      }

      // ---- 转账箭头 ----
      Row() {
        AppIcon({ icon: 'arrow-right', fontSize: 20, fontColor: this.getPrimaryColor() })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 4, bottom: 4 })

      // ---- 转入钱包 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 4 } }) {
        Column() {
          Text(this.getT().toWallet)
            .fontSize(13)
            .fontColor(this.getSecondaryTextColor())
            .margin({ bottom: 8 })

          this.GroupedWalletSelector('to')
        }
        .alignItems(HorizontalAlign.Start)
      }

      // ---- 金额输入（动态：同币种 vs 跨币种） ----
      // 核心业务红线：跨币种时必须展开为双金额输入
      if (this.isCrossCurrency()) {
        // 跨币种：显示两个独立的金额输入框
        UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
          Column() {
            // 转出金额
            Text(`${this.getT().fromAmount} (${this.getFromWalletCurrency()})`)
              .fontSize(13)
              .fontColor(this.getSecondaryTextColor())
              .margin({ bottom: 8 })

            Row() {
              Text(this.getFromWalletSymbol())
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getPrimaryTextColor())
                .margin({ right: 8 })

              UniInput({
                textValue: $fromAmountText,
                placeholder: '0.00',
                inputType: InputType.NUMBER_DECIMAL,
                heightValue: 48
              })
            }
            .width('100%')

            // 分隔线
            Row()
              .width('100%')
              .height(1)
              .backgroundColor(this.getDividerColor())
              .margin({ top: 16, bottom: 16 })

            // 转入金额
            Text(`${this.getT().toAmount} (${this.getToWalletCurrency()})`)
              .fontSize(13)
              .fontColor(this.getSecondaryTextColor())
              .margin({ bottom: 8 })

            Row() {
              Text(this.getToWalletSymbol())
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getPrimaryTextColor())
                .margin({ right: 8 })

              UniInput({
                textValue: $toAmountText,
                placeholder: '0.00',
                inputType: InputType.NUMBER_DECIMAL,
                heightValue: 48
              })
            }
            .width('100%')

            // 跨币种提示
            Text(this.getT().crossCurrencyTip)
              .fontSize(11)
              .fontColor(this.getSecondaryTextColor())
              .margin({ top: 12 })
              .width('100%')
              .textAlign(TextAlign.Center)
          }
        }
      } else {
        // 同币种：显示一个金额输入框
        UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
          Column() {
            Text(`${this.getT().transferAmount} (${this.getFromWalletCurrency()})`)
              .fontSize(13)
              .fontColor(this.getSecondaryTextColor())
              .margin({ bottom: 8 })

            Row() {
              Text(this.getFromWalletSymbol())
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getPrimaryTextColor())
                .margin({ right: 8 })

              UniInput({
                textValue: $fromAmountText,
                placeholder: '0.00',
                inputType: InputType.NUMBER_DECIMAL,
                heightValue: 56
              })
            }
            .width('100%')
          }
        }
      }

      // ---- 日期时间选择 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        this.DateRow('transfer')
      }

      // ---- 备注 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Text(this.getT().note)
            .fontSize(13)
            .fontColor(this.getSecondaryTextColor())
            .margin({ bottom: 8 })

          UniInput({
            textValue: $transferNoteText,
            placeholder: this.getT().addNote,
            inputType: InputType.Normal,
            heightValue: 44
          })
        }
      }

      // ---- 图片凭证 ----
      UniCard({ marginValue: { left: 16, right: 16, top: 12 } }) {
        Column() {
          Text(this.getT().addImage)
            .fontSize(13)
            .fontColor(this.getSecondaryTextColor())
            .margin({ bottom: 8 })

          if (this.transferImageUri === '') {
            Row() {
              AppIcon({ icon: 'image', fontSize: 18 })
                .margin({ right: 8 })

              Text(this.getT().addImage)
                .fontSize(14)
                .fontColor(this.getPrimaryTextColor())
            }
            .width('100%')
            .height(60)
            .justifyContent(FlexAlign.Center)
            .borderRadius(8)
            .border({ width: 1, color: this.getDividerColor(), style: BorderStyle.Dashed })
            .onClick(() => {
              this.pickImage('transfer')
            })
          } else {
            Row() {
              Image(this.transferImageUri)
                .width(60)
                .height(60)
                .objectFit(ImageFit.Cover)
                .borderRadius(8)
                .margin({ right: 12 })

              Column() {
                Text(this.getT().imageAdded)
                  .fontSize(14)
                  .fontColor(this.getPrimaryTextColor())

                Text(this.getT().clickToChange)
                  .fontSize(12)
                  .fontColor(this.getSecondaryTextColor())
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              AppIcon({ icon: 'x', fontSize: 18, fontColor: this.getSecondaryTextColor() })
                .onClick(() => {
                  this.transferImageUri = ''
                })
            }
            .width('100%')
            .onClick(() => {
              this.pickImage('transfer')
            })
          }
        }
        .alignItems(HorizontalAlign.Start)
      }

      // ---- 保存按钮 ----
      UniButton({
        marginValue: { left: 16, right: 16, top: 20, bottom: 24 },
        onClickHandler: () => {
          this.saveTransfer()
        }
      }) {
        Text(this.getT().save)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getButtonFontColor())
      }
    }
  }

  // ==================== 分组钱包选择器 ====================
  @Builder
  GroupedWalletSelector(target: string) {
    Column() {
      this.WalletTypeGroup(target, WalletType.Cash)
      this.WalletTypeGroup(target, WalletType.Savings)
      this.WalletTypeGroup(target, WalletType.Credit)
      this.WalletTypeGroup(target, WalletType.EWallet)
    }
    .width('100%')
  }

  @Builder
  WalletTypeGroup(target: string, wType: WalletType) {
    if (this.getWalletsByType(wType).length > 0) {
      Column() {
        Text(`${WalletTypeIcon.get(wType)} ${this.getWalletTypeLabel(wType)}`)
          .fontSize(12)
          .fontColor(this.getSecondaryTextColor())
          .margin({ bottom: 6, top: 6 })

        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.getWalletsByType(wType), (wallet: Wallet) => {
              Column() {
                Text(`${wallet.icon} ${wallet.name}`)
                  .fontSize(13)
                  .fontColor(this.isWalletSelected(target, wallet.id) ? Color.White : this.getPrimaryTextColor())

                Text(wallet.currency)
                  .fontSize(10)
                  .fontColor(this.isWalletSelected(target, wallet.id) ? '#FFFFFFCC' : this.getSecondaryTextColor())
                  .margin({ top: 2 })
              }
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 20)
              .backgroundColor(this.isWalletSelected(target, wallet.id) ? wallet.color : this.getChipBackground())
              .border(this.isWalletSelected(target, wallet.id)
                ? { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
                : { width: 1, color: this.getDividerColor(), style: BorderStyle.Solid })
              .onClick(() => {
                this.selectWallet(target, wallet.id)
              })
            }, (wallet: Wallet) => wallet.id)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  // ==================== 平台选择芯片行 ====================
  @Builder
  PlatformChipRow() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.platformList, (platform: Platform) => {
          Column() {
            Text(`${platform.icon} ${platform.name}`)
              .fontSize(13)
              .fontColor(this.selectedPlatformId === platform.id ? Color.White : this.getPrimaryTextColor())
          }
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 20)
          .backgroundColor(this.selectedPlatformId === platform.id ? platform.color : this.getChipBackground())
          .border(this.selectedPlatformId === platform.id
            ? { width: 0, color: Color.Transparent, style: BorderStyle.Solid }
            : { width: 1, color: this.getDividerColor(), style: BorderStyle.Solid })
          .onClick(() => {
            this.selectedPlatformId = platform.id
          })
        }, (platform: Platform) => platform.id)
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  // ==================== 分类网格 ====================
  @Builder
  CategoryGrid(categories: Category[]) {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
      ForEach(categories, (cat: Category) => {
        Column() {
          Text(cat.icon)
            .fontSize(24)

          Text(cat.name)
            .fontSize(11)
            .fontColor(this.selectedCategoryId === cat.id ? cat.color : this.getSecondaryTextColor())
            .margin({ top: 4 })
        }
        .width(64)
        .height(68)
        .justifyContent(FlexAlign.Center)
        .borderRadius(this.currentStyle === UIStyle.Brutalism ? 0 : 10)
        .backgroundColor(this.selectedCategoryId === cat.id ? `${cat.color}18` : Color.Transparent)
        .border(this.selectedCategoryId === cat.id
          ? { width: 2, color: cat.color, style: BorderStyle.Solid }
          : { width: 0, color: Color.Transparent, style: BorderStyle.Solid })
        .margin({ bottom: 4 })
        .onClick(() => {
          this.selectedCategoryId = cat.id
        })
      }, (cat: Category) => cat.id)
    }
  }

  // ==================== 日期时间选择行 ====================
  @Builder
  DateRow(target: string) {
    Row() {
      Text(this.getT().dateAndTime)
        .fontSize(14)
        .fontColor(this.getSecondaryTextColor())

      Blank()

      Row() {
        Text(this.formatDateTimeByTarget(target))
          .fontSize(14)
          .fontColor(this.getPrimaryTextColor())
          .margin({ right: 6 })

        AppIcon({ icon: 'calendar', fontSize: 18 })
      }
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .onClick(() => {
      this.showDatePicker(target)
    })
  }

  // ==================== 保存逻辑 ====================

  /**
   * 保存支出/收入记录
   */
  private saveExpenseOrIncome(type: TransactionType): void {
    const amount = parseFloat(this.amountText)
    if (isNaN(amount) || amount <= 0) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseEnterAmount })
      } catch (e) {
        console.error('showToast failed:', e)
      }
      return
    }
    if (this.selectedWalletId === '') {
      try {
        this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseSelectWallet })
      } catch (e) {
        console.error('showToast failed:', e)
      }
      return
    }
    if (this.selectedCategoryId === '' && type === TransactionType.Expense) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseSelectCategory })
      } catch (e) {
        console.error('showToast failed:', e)
      }
      return
    }
    if (this.selectedPlatformId === '') {
      try {
        this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseSelectPlatform })
      } catch (e) {
        console.error('showToast failed:', e)
      }
      return
    }

    const wallet = this.findWallet(this.selectedWalletId)
    if (!wallet) {
      return
    }

    // 编辑模式：保留原始 id 和 createdAt，覆盖其他字段
    if (this.isEditMode() && this.editTransaction) {
      const tx = this.editTransaction
      tx.type = type
      tx.amount = amount
      tx.currency = this.selectedCurrency
      tx.walletId = this.selectedWalletId
      tx.platformId = this.selectedPlatformId
      // 收入自动设为 'income'，支出使用用户选择的分类
      tx.category = type === TransactionType.Income ? 'income' : this.selectedCategoryId
      tx.datetime = this.selectedDate || this.getNowISO()
      tx.note = this.noteText
      if (this.selectedImageUri !== '') {
        tx.imageUri = this.selectedImageUri
        tx.hasImage = true
      }
      this.onSave(tx)
      this.resetForm()
      this.onClose()
      return
    }

    // 新增模式
    const tx = new Transaction(
      `tx_${Date.now()}`,
      type,
      amount,
      this.selectedCurrency,
      this.selectedPlatformId,
      this.selectedWalletId,
      type === TransactionType.Income ? 'income' : this.selectedCategoryId,
      this.selectedDate || this.getNowISO(),
      this.noteText,
      Date.now()
    )
    if (this.selectedImageUri !== '') {
      tx.imageUri = this.selectedImageUri
      tx.hasImage = true
    }

    this.onSave(tx)
    this.resetForm()
    this.onClose()
  }

  /**
   * 保存转账记录
   * type 严格标记为 'transfer'，确保后续在数据看板和消费日历统计中被剔除
   */
  private saveTransfer(): void {
    if (this.fromWalletId === '' || this.toWalletId === '') {
      try {
        this.getUIContext().getPromptAction().showToast({ message: this.getT().needTwoWallets })
      } catch (e) {
        console.error('showToast failed:', e)
      }
      return
    }
    if (this.fromWalletId === this.toWalletId) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: this.getT().needTwoWallets })
      } catch (e) {
        console.error('showToast failed:', e)
      }
      return
    }

    const fromWallet = this.findWallet(this.fromWalletId)
    const toWallet = this.findWallet(this.toWalletId)
    if (!fromWallet || !toWallet) {
      return
    }

    const isCross = this.isCrossCurrency()
    let fromAmount: number = 0
    let toAmount: number = 0

    if (isCross) {
      // 跨币种转账：两个金额都必须有效
      fromAmount = parseFloat(this.fromAmountText)
      toAmount = parseFloat(this.toAmountText)
      if (isNaN(fromAmount) || fromAmount <= 0) {
        try {
          this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseEnterAmount })
        } catch (e) {
          console.error('showToast failed:', e)
        }
        return
      }
      if (isNaN(toAmount) || toAmount <= 0) {
        try {
          this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseEnterAmount })
        } catch (e) {
          console.error('showToast failed:', e)
        }
        return
      }
    } else {
      // 同币种转账：只需一个金额
      fromAmount = parseFloat(this.fromAmountText)
      toAmount = fromAmount
      if (isNaN(fromAmount) || fromAmount <= 0) {
        try {
          this.getUIContext().getPromptAction().showToast({ message: this.getT().pleaseEnterAmount })
      } catch (e) {
        console.error('showToast failed:', e)
      }
      return
    }

    // 编辑模式：保留原始 id 和 createdAt，覆盖其他字段
    if (this.isEditMode() && this.editTransaction) {
      const tx = this.editTransaction
      tx.type = TransactionType.Transfer
      tx.amount = fromAmount
      tx.currency = fromWallet.currency
      tx.walletId = this.fromWalletId
      tx.platformId = this.platformList.length > 0 ? this.platformList[0].id : ''
      tx.category = 'transfer'
      tx.datetime = this.transferDate || this.getNowISO()
      tx.note = this.transferNoteText
      tx.fromWalletId = this.fromWalletId
      tx.toWalletId = this.toWalletId
      tx.fromAmount = fromAmount
      tx.toAmount = toAmount
      tx.fromCurrency = fromWallet.currency
      tx.toCurrency = toWallet.currency
      if (this.transferImageUri !== '') {
        tx.imageUri = this.transferImageUri
        tx.hasImage = true
      }
      this.onSave(tx)
      this.resetForm()
      this.onClose()
      return
    }

    // 新增模式：构建转账交易记录，type 严格为 'transfer'，category 也为 'transfer'
    const tx = new Transaction()
    tx.id = `tx_${Date.now()}`
    tx.type = TransactionType.Transfer
    tx.amount = fromAmount
    tx.currency = fromWallet.currency
    tx.walletId = this.fromWalletId
    tx.platformId = this.platformList.length > 0 ? this.platformList[0].id : ''
    tx.category = 'transfer'
    tx.datetime = this.transferDate || this.getNowISO()
    tx.note = this.transferNoteText
    tx.createdAt = Date.now()
    // 转账特有字段
    tx.fromWalletId = this.fromWalletId
    tx.toWalletId = this.toWalletId
    tx.fromAmount = fromAmount
    tx.toAmount = toAmount
    tx.fromCurrency = fromWallet.currency
    tx.toCurrency = toWallet.currency
    if (this.transferImageUri !== '') {
      tx.imageUri = this.transferImageUri
      tx.hasImage = true
    }

    this.onSave(tx)
    this.resetForm()
    this.onClose()
  }
}
}
