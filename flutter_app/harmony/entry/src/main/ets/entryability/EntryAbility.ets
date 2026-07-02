import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { flutterApplication } from '@ohos/flutter_ohos';

const DOMAIN = 0x0000;

/**
 * ScanPDF 鸿蒙入口 Ability
 */
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'ScanPDF', 'EntryAbility onCreate');
    // Flutter 初始化
    flutterApplication.instance.onCreate(this.context, want, launchParam);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'ScanPDF', 'EntryAbility onDestroy');
    flutterApplication.instance.onDestroy();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'ScanPDF', 'EntryAbility onWindowStageCreate');
    // Flutter 窗口创建
    flutterApplication.instance.onWindowStageCreate(windowStage, this.context);
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'ScanPDF', 'EntryAbility onWindowStageDestroy');
    flutterApplication.instance.onWindowStageDestroy();
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'ScanPDF', 'EntryAbility onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'ScanPDF', 'EntryAbility onBackground');
  }
}
