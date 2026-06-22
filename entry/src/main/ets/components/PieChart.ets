/**
 * PieChart 环形图组件
 * 基于 ArkUI Canvas + CanvasRenderingContext2D 绘制
 * 支持动画、间隙、中心标签、图例
 */
import { PrimaryTextColorMap, SecondaryTextColorMap } from '../constants/UIStyleConst'

// ==================== 数据接口 ====================

export class PieChartData {
  value: number = 0
  color: string = ''
  label: string = ''
}

// ==================== PieChart 环形图组件 ====================

@Component
export struct PieChart {
  @Prop data: PieChartData[] = []
  @Prop innerRadius: number = 55
  @Prop outerRadius: number = 90
  @Prop centerLabel: string = ''
  @Prop centerValue: string = ''
  @Prop chartWidth: number = 200
  @Prop chartHeight: number = 200
  @Prop paddingAngle: number = 3 // 段间间隙角度（度）
  @Prop animDuration: number = 600 // 动画时长（ms）
  @State animProgress: number = 0
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  aboutToAppear() {
    try {
      this.getUIContext()?.animateTo({ duration: this.animDuration, curve: Curve.EaseOut }, () => {
        this.animProgress = 1
      })
    } catch (e) {
      this.animProgress = 1
    }
  }

  build() {
    Stack() {
      Canvas(this.context)
        .width(this.chartWidth)
        .height(this.chartHeight)
        .onReady(() => {
          this.drawChart()
        })

      // 中心标签
      Column() {
        if (this.centerValue) {
          Text(this.centerValue)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
        }
        if (this.centerLabel) {
          Text(this.centerLabel)
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width(this.chartWidth)
    .height(this.chartHeight)
  }

  private drawChart() {
    const ctx = this.context
    const cx = this.chartWidth / 2
    const cy = this.chartHeight / 2
    const total = this.data.reduce((sum: number, d: PieChartData) => sum + d.value, 0)
    if (total <= 0) {
      return
    }

    ctx.clearRect(0, 0, this.chartWidth, this.chartHeight)

    const gapRad = this.paddingAngle * Math.PI / 180
    let startAngle = -Math.PI / 2 // 从顶部开始

    for (let i = 0; i < this.data.length; i++) {
      const item = this.data[i]
      if (item.value <= 0) {
        continue
      }
      const sweepAngle = (item.value / total) * 2 * Math.PI * this.animProgress

      // 只有当扇形角度大于两倍间隙时才绘制，避免间隙吞没小扇形
      if (sweepAngle > gapRad * 2) {
        const arcStart = startAngle + gapRad
        const arcEnd = startAngle + sweepAngle - gapRad

        ctx.beginPath()
        // 外弧：顺时针
        ctx.arc(cx, cy, this.outerRadius, arcStart, arcEnd, false)
        // 内弧：逆时针（形成环形闭合路径）
        ctx.arc(cx, cy, this.innerRadius, arcEnd, arcStart, true)
        ctx.closePath()
        ctx.fillStyle = item.color
        ctx.fill()
      }

      startAngle += sweepAngle
    }
  }
}

// ==================== PieChartLegend 图例组件 ====================

@Component
export struct PieChartLegend {
  @Prop data: PieChartData[] = []

  build() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
      ForEach(this.data, (item: PieChartData) => {
        Row({ space: 6 }) {
          // 颜色圆点
          Row()
            .width(10)
            .height(10)
            .borderRadius(5)
            .backgroundColor(item.color)

          // 标签
          Text(item.label)
            .fontSize(12)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 数值
          Text(`${item.value}`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
        }
        .alignItems(VerticalAlign.Center)
      }, (item: PieChartData, index: number) => `${item.label}_${index}`)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }
}

// ==================== 预览 ====================

@Preview
@Component
struct PieChartPreview {
  @State sampleData: PieChartData[] = [
    { value: 1200, color: '#3B82F6', label: '餐饮' },
    { value: 800, color: '#22C55E', label: '交通' },
    { value: 600, color: '#F59E0B', label: '购物' },
    { value: 400, color: '#EF4444', label: '娱乐' },
    { value: 300, color: '#8B5CF6', label: '其他' }
  ]

  build() {
    Scroll() {
      Column({ space: 24 }) {
        Text('PieChart 环形图预览')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })

        // 基础用法
        Column() {
          Text('基础环形图')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 12 })

          PieChart({
            data: this.sampleData,
            innerRadius: 55,
            outerRadius: 90,
            centerValue: '¥3300',
            centerLabel: '总支出',
            chartWidth: 200,
            chartHeight: 200
          })

          PieChartLegend({ data: this.sampleData })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)

        // 大尺寸
        Column() {
          Text('大尺寸环形图')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 12 })

          PieChart({
            data: this.sampleData,
            innerRadius: 70,
            outerRadius: 110,
            centerValue: '¥3300',
            centerLabel: '本月总支出',
            chartWidth: 260,
            chartHeight: 260,
            paddingAngle: 2
          })

          PieChartLegend({ data: this.sampleData })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)

        // 单项数据
        Column() {
          Text('单项数据')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 12 })

          PieChart({
            data: [{ value: 100, color: '#3B82F6', label: '餐饮' }],
            innerRadius: 55,
            outerRadius: 90,
            centerValue: '¥100',
            centerLabel: '餐饮',
            chartWidth: 200,
            chartHeight: 200,
            paddingAngle: 0
          })

          PieChartLegend({ data: [{ value: 100, color: '#3B82F6', label: '餐饮' }] })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F0F0')
    .scrollBar(BarState.Auto)
  }
}
