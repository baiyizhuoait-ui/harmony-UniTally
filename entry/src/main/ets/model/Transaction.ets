/**
 * 交易记录模型
 * 核心数据实体，支持支出/收入/转账三种类型
 * 转账类型在数据看板和消费日历统计中必须被剔除
 */
import { TransactionType } from '../constants/CurrencyConst'

@Observed
export class Transaction {
  id: string = ''
  type: TransactionType = TransactionType.Expense
  amount: number = 0
  currency: string = 'CNY'
  platformId: string = ''
  walletId: string = ''
  category: string = ''
  datetime: string = ''   // ISO 时间字符串
  note: string = ''
  createdAt: number = 0

  // 跨币种转账特有字段
  fromWalletId: string = ''
  toWalletId: string = ''
  fromAmount: number = 0
  toAmount: number = 0
  fromCurrency: string = ''
  toCurrency: string = ''

  // 图片相关字段
  imageUri: string = ''           // 图片URI（从相册选择或拍摄）
  imageThumbnail: string = ''     // 缩略图URI（用于列表展示）
  hasImage: boolean = false       // 是否包含图片

  constructor(
    id: string = '',
    type: TransactionType = TransactionType.Expense,
    amount: number = 0,
    currency: string = 'CNY',
    platformId: string = '',
    walletId: string = '',
    category: string = '',
    datetime: string = '',
    note: string = '',
    createdAt: number = Date.now()
  ) {
    this.id = id
    this.type = type
    this.amount = amount
    this.currency = currency
    this.platformId = platformId
    this.walletId = walletId
    this.category = category
    this.datetime = datetime
    this.note = note
    this.createdAt = createdAt
  }

  /**
   * 判断是否为跨币种转账
   */
  isCrossCurrencyTransfer(): boolean {
    return this.type === TransactionType.Transfer &&
      this.fromCurrency !== '' &&
      this.toCurrency !== '' &&
      this.fromCurrency !== this.toCurrency
  }

  /**
   * 判断是否应被纳入统计（转账不纳入）
   */
  shouldCountInStats(): boolean {
    return this.type !== TransactionType.Transfer
  }

  /**
   * 序列化为 JSON 对象
   */
  toJson(): Record<string, Object> {
    const result: Record<string, Object> = {
      'id': this.id,
      'type': this.type,
      'amount': this.amount,
      'currency': this.currency,
      'platformId': this.platformId,
      'walletId': this.walletId,
      'category': this.category,
      'datetime': this.datetime,
      'note': this.note,
      'createdAt': this.createdAt
    }
    if (this.type === TransactionType.Transfer) {
      result['fromWalletId'] = this.fromWalletId
      result['toWalletId'] = this.toWalletId
      result['fromAmount'] = this.fromAmount
      result['toAmount'] = this.toAmount
      result['fromCurrency'] = this.fromCurrency
      result['toCurrency'] = this.toCurrency
    }
    // 图片字段
    if (this.hasImage) {
      result['imageUri'] = this.imageUri
      result['imageThumbnail'] = this.imageThumbnail
      result['hasImage'] = this.hasImage
    }
    return result
  }
}

/**
 * 从 JSON 对象反序列化 Transaction
 */
export function createTransactionFromJson(json: Record<string, Object>): Transaction {
  const tx = new Transaction()
  const id = json['id']
  tx.id = id !== undefined && id !== null ? String(id) : ''
  const type = json['type']
  if (type !== undefined && type !== null) {
    if (type === TransactionType.Expense || type === TransactionType.Income || type === TransactionType.Transfer) {
      tx.type = type as TransactionType
    } else {
      tx.type = TransactionType.Expense
    }
  }
  const amount = json['amount']
  tx.amount = amount !== undefined && amount !== null ? Number(amount) : 0
  const currency = json['currency']
  tx.currency = currency !== undefined && currency !== null ? String(currency) : 'CNY'
  const platformId = json['platformId']
  tx.platformId = platformId !== undefined && platformId !== null ? String(platformId) : ''
  const walletId = json['walletId']
  tx.walletId = walletId !== undefined && walletId !== null ? String(walletId) : ''
  const category = json['category']
  tx.category = category !== undefined && category !== null ? String(category) : ''
  const datetime = json['datetime']
  tx.datetime = datetime !== undefined && datetime !== null ? String(datetime) : ''
  const note = json['note']
  tx.note = note !== undefined && note !== null ? String(note) : ''
  const createdAt = json['createdAt']
  tx.createdAt = createdAt !== undefined && createdAt !== null ? Number(createdAt) : 0
  const fromWalletId = json['fromWalletId']
  tx.fromWalletId = fromWalletId !== undefined && fromWalletId !== null ? String(fromWalletId) : ''
  const toWalletId = json['toWalletId']
  tx.toWalletId = toWalletId !== undefined && toWalletId !== null ? String(toWalletId) : ''
  const fromAmount = json['fromAmount']
  tx.fromAmount = fromAmount !== undefined && fromAmount !== null ? Number(fromAmount) : 0
  const toAmount = json['toAmount']
  tx.toAmount = toAmount !== undefined && toAmount !== null ? Number(toAmount) : 0
  const fromCurrency = json['fromCurrency']
  tx.fromCurrency = fromCurrency !== undefined && fromCurrency !== null ? String(fromCurrency) : ''
  const toCurrency = json['toCurrency']
  tx.toCurrency = toCurrency !== undefined && toCurrency !== null ? String(toCurrency) : ''
  const imageUri = json['imageUri']
  tx.imageUri = imageUri !== undefined && imageUri !== null ? String(imageUri) : ''
  const imageThumbnail = json['imageThumbnail']
  tx.imageThumbnail = imageThumbnail !== undefined && imageThumbnail !== null ? String(imageThumbnail) : ''
  const hasImage = json['hasImage']
  tx.hasImage = hasImage !== undefined && hasImage !== null ? Boolean(hasImage) : false
  return tx
}
