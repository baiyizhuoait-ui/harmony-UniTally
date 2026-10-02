/**
 * 预算模型
 * 用于设置某分类的月度/周期预算
 * 包含已花费金额、颜色标识、日期范围和提醒设置
 */
@Observed
export class Budget {
  id: string = ''
  name: string = ''
  amount: number = 0
  spent: number = 0
  category: string = ''
  color: string = '#607D8B'
  startDate: string = ''
  endDate: string = ''
  note: string = ''
  period: string = '1m'
  notifyEnabled: boolean = false
  notifyDaysBefore: number = 3
  currency: string = 'CNY'
  createdAt: number = 0

  constructor(
    id: string = '',
    name: string = '',
    amount: number = 0,
    spent: number = 0,
    category: string = '',
    color: string = '#607D8B',
    startDate: string = '',
    endDate: string = '',
    note: string = '',
    period: string = '1m',
    notifyEnabled: boolean = false,
    notifyDaysBefore: number = 3,
    currency: string = 'CNY',
    createdAt: number = Date.now()
  ) {
    this.id = id
    this.name = name
    this.amount = amount
    this.spent = spent
    this.category = category
    this.color = color
    this.startDate = startDate
    this.endDate = endDate
    this.note = note
    this.period = period
    this.notifyEnabled = notifyEnabled
    this.notifyDaysBefore = notifyDaysBefore
    this.currency = currency
    this.createdAt = createdAt
  }

  /**
   * 计算预算使用百分比
   */
  getUsagePercent(): number {
    if (this.amount <= 0) {
      return 0
    }
    return Math.min((this.spent / this.amount) * 100, 100)
  }

  /**
   * 判断预算是否超支
   */
  isOverBudget(): boolean {
    return this.spent > this.amount
  }

  /**
   * 获取剩余预算
   */
  getRemaining(): number {
    return Math.max(0, this.amount - this.spent)
  }

  /**
   * 获取超支金额
   */
  getOverAmount(): number {
    if (this.spent <= this.amount) {
      return 0
    }
    return this.spent - this.amount
  }

  toJson(): Record<string, Object> {
    return {
      'id': this.id,
      'name': this.name,
      'amount': this.amount,
      'spent': this.spent,
      'category': this.category,
      'color': this.color,
      'startDate': this.startDate,
      'endDate': this.endDate,
      'note': this.note,
      'period': this.period,
      'notifyEnabled': this.notifyEnabled,
      'notifyDaysBefore': this.notifyDaysBefore,
      'currency': this.currency,
      'createdAt': this.createdAt
    }
  }
}

/**
 * 从 JSON 对象反序列化 Budget
 */
export function createBudgetFromJson(json: Record<string, Object>): Budget {
  const budget = new Budget()
  const id = json['id']
  budget.id = id !== undefined && id !== null ? String(id) : ''
  const name = json['name']
  budget.name = name !== undefined && name !== null ? String(name) : ''
  const amount = json['amount']
  budget.amount = amount !== undefined && amount !== null ? Number(amount) : 0
  const spent = json['spent']
  budget.spent = spent !== undefined && spent !== null ? Number(spent) : 0
  const category = json['category']
  budget.category = category !== undefined && category !== null ? String(category) : ''
  const color = json['color']
  budget.color = color !== undefined && color !== null ? String(color) : '#607D8B'
  const startDate = json['startDate']
  budget.startDate = startDate !== undefined && startDate !== null ? String(startDate) : ''
  const endDate = json['endDate']
  budget.endDate = endDate !== undefined && endDate !== null ? String(endDate) : ''
  const note = json['note']
  budget.note = note !== undefined && note !== null ? String(note) : ''
  const period = json['period']
  budget.period = period !== undefined && period !== null ? String(period) : '1m'
  const notifyEnabled = json['notifyEnabled']
  budget.notifyEnabled = notifyEnabled !== undefined && notifyEnabled !== null ? Boolean(notifyEnabled) : false
  const notifyDaysBefore = json['notifyDaysBefore']
  budget.notifyDaysBefore = notifyDaysBefore !== undefined && notifyDaysBefore !== null ? Number(notifyDaysBefore) : 3
  const currency = json['currency']
  budget.currency = currency !== undefined && currency !== null ? String(currency) : 'CNY'
  const createdAt = json['createdAt']
  budget.createdAt = createdAt !== undefined && createdAt !== null ? Number(createdAt) : 0
  return budget
}
