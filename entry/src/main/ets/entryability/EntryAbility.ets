/**
 * 应用入口 Ability
 * Stage 模式下应用的入口点
 */
import UIAbility from '@ohos.app.ability.UIAbility'
import AbilityConstant from '@ohos.app.ability.AbilityConstant'
import Want from '@ohos.app.ability.Want'
import window from '@ohos.window'
import { storageUtil } from '../utils/StorageUtil'

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('[EntryAbility] onCreate')
    // 初始化持久化存储，将数据同步到 AppStorage
    storageUtil.init(this.context)
  }

  onDestroy(): void {
    console.info('[EntryAbility] onDestroy')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.info('[EntryAbility] onWindowStageCreate')
    // 设置主窗口
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        console.error(`[EntryAbility] loadContent failed: ${JSON.stringify(err)}`)
        return
      }
      console.info('[EntryAbility] loadContent success')
    })
  }

  onWindowStageDestroy(): void {
    console.info('[EntryAbility] onWindowStageDestroy')
  }

  onForeground(): void {
    console.info('[EntryAbility] onForeground')
  }

  onBackground(): void {
    console.info('[EntryAbility] onBackground')
  }
}
