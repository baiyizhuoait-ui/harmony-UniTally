/**
 * 分类模型
 * 用于支出/收入的分类标记
 */
import { getTranslation, getCurrentLanguage } from '../constants/I18n'

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

  static getLocalizedName(key: string): string {
    const t = getTranslation(getCurrentLanguage())
    const nameMap: Map<string, string> = new Map([
      ['cat_food', t.catFood],
      ['cat_transport', t.catTransport],
      ['cat_shopping', t.catShopping],
      ['cat_housing', t.catHousing],
      ['cat_entertainment', t.catEntertainment],
      ['cat_medical', t.catMedical],
      ['cat_education', t.catEducation],
      ['cat_other_expense', t.catOtherExpense],
      ['cat_salary', t.catSalary],
      ['cat_bonus', t.catBonus],
      ['cat_investment', t.catInvestment],
      ['cat_sidejob', t.catSidejob],
      ['cat_other_income', t.catOtherIncome]
    ])
    return nameMap.get(key) ?? key
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

// Get default expense categories with localized names (called at display time)
export function getDefaultExpenseCategories(): Category[] {
  return [
    new Category('cat_food', Category.getLocalizedName('cat_food'), '🍜', '#FF7043', 0),
    new Category('cat_transport', Category.getLocalizedName('cat_transport'), '🚗', '#42A5F5', 1),
    new Category('cat_shopping', Category.getLocalizedName('cat_shopping'), '🛍️', '#AB47BC', 2),
    new Category('cat_housing', Category.getLocalizedName('cat_housing'), '🏠', '#66BB6A', 3),
    new Category('cat_entertainment', Category.getLocalizedName('cat_entertainment'), '🎮', '#FFA726', 4),
    new Category('cat_medical', Category.getLocalizedName('cat_medical'), '🏥', '#EF5350', 5),
    new Category('cat_education', Category.getLocalizedName('cat_education'), '📚', '#5C6BC0', 6),
    new Category('cat_other_expense', Category.getLocalizedName('cat_other_expense'), '📌', '#78909C', 7)
  ]
}

// Get default income categories with localized names (called at display time)
export function getDefaultIncomeCategories(): Category[] {
  return [
    new Category('cat_salary', Category.getLocalizedName('cat_salary'), '💼', '#43A047', 0),
    new Category('cat_bonus', Category.getLocalizedName('cat_bonus'), '🎁', '#FFB300', 1),
    new Category('cat_investment', Category.getLocalizedName('cat_investment'), '📈', '#1E88E5', 2),
    new Category('cat_sidejob', Category.getLocalizedName('cat_sidejob'), '🔧', '#8E24AA', 3),
    new Category('cat_other_income', Category.getLocalizedName('cat_other_income'), '📌', '#78909C', 4)
  ]
}

// Legacy static arrays for backward compatibility
export const DEFAULT_EXPENSE_CATEGORIES: Category[] = getDefaultExpenseCategories()
export const DEFAULT_INCOME_CATEGORIES: Category[] = getDefaultIncomeCategories()
