/**
 * 分类模型
 * 用于支出/收入的分类标记
 */
@Observed
export class Category {
  id: string = ''
  name: string = ''
  icon: string = ''
  color: string = '#607D8B'
  order: number = 0

  constructor(
    id: string = '',
    name: string = '',
    icon: string = '',
    color: string = '#607D8B',
    order: number = 0
  ) {
    this.id = id
    this.name = name
    this.icon = icon
    this.color = color
    this.order = order
  }

  toJson(): Record<string, Object> {
    return {
      'id': this.id,
      'name': this.name,
      'icon': this.icon,
      'color': this.color,
      'order': this.order
    }
  }
}

/**
 * 从 JSON 对象反序列化 Category
 */
export function createCategoryFromJson(json: Record<string, Object>): Category {
  const cat = new Category()
  const id = json['id']
  cat.id = id !== undefined && id !== null ? String(id) : ''
  const name = json['name']
  cat.name = name !== undefined && name !== null ? String(name) : ''
  const icon = json['icon']
  cat.icon = icon !== undefined && icon !== null ? String(icon) : ''
  const color = json['color']
  cat.color = color !== undefined && color !== null ? String(color) : '#607D8B'
  const order = json['order']
  cat.order = order !== undefined && order !== null ? Number(order) : 0
  return cat
}

// 默认支出分类
export const DEFAULT_EXPENSE_CATEGORIES: Category[] = [
  new Category('cat_food', '餐饮', '🍜', '#FF7043', 0),
  new Category('cat_transport', '交通', '🚗', '#42A5F5', 1),
  new Category('cat_shopping', '购物', '🛍️', '#AB47BC', 2),
  new Category('cat_housing', '住房', '🏠', '#66BB6A', 3),
  new Category('cat_entertainment', '娱乐', '🎮', '#FFA726', 4),
  new Category('cat_medical', '医疗', '🏥', '#EF5350', 5),
  new Category('cat_education', '教育', '📚', '#5C6BC0', 6),
  new Category('cat_other_expense', '其他', '📌', '#78909C', 7)
]

// 默认收入分类
export const DEFAULT_INCOME_CATEGORIES: Category[] = [
  new Category('cat_salary', '工资', '💼', '#43A047', 0),
  new Category('cat_bonus', '奖金', '🎁', '#FFB300', 1),
  new Category('cat_investment', '投资', '📈', '#1E88E5', 2),
  new Category('cat_sidejob', '兼职', '🔧', '#8E24AA', 3),
  new Category('cat_other_income', '其他', '📌', '#78909C', 4)
]
