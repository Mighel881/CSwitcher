#import "CSView.h"
#import "shared.h"
static BOOL enable(void) {
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.broganminer.cswitcher~prefs.plist"];
    BOOL enable = (prefs)? [prefs [@"enable"] boolValue] : YES;
    [prefs release];
    return enable;
}

static SBControlCenterSectionView *CSContainer;
static SBControlCenterSeparatorView *CSSeparator;
static int oldOrientation;
%group CSwitcher

%hook SBAppSliderController
%new
+ (id)sharedController {
  return [(SBUIController *)[%c(SBUIController) sharedInstance] _appSliderController];
}
%end

%hook SBControlCenterController
- (void)_endPresentation {
  %orig;
  if ([CSView sharedView].inEdit){
    if (![CSView sharedView].snapShots) {
      [[CSView sharedView] setIconsEditing:NO];
    }
    else {
      [[CSView sharedView] stopContainersEditing];
    }
  } 
  [CSView sharedView].contentOffset = CGPointMake(0,0);
}
- (BOOL)handleMenuButtonTap {
  if ([CSView sharedView].inEdit){
    if (![CSView sharedView].snapShots) {
      [[CSView sharedView] setIconsEditing:NO];
    }
    else {
      [[CSView sharedView] stopContainersEditing];
    }
    return YES;
  }
  else {
    return %orig;
  }
}
%end

%hook SBUIController
- (BOOL)handleMenuDoubleTap {
  [[%c(SBControlCenterController) sharedInstance] presentAnimated:YES];
  return YES;
}

%end

%hook SBAppSwitcherModel
- (void)addToFront:(id)arg1 {
  %orig(arg1);
  [[CSView sharedView] moveAppToFront:arg1];
}
%end
%hook SpringBoard
- (void)noteInterfaceOrientationChanged:(long long)arg1 duration:(double)arg2{
    %orig;
    [[CSView sharedView] layoutIconsWithIDS:[[CSView sharedView] currentIDS]];
}
%end
%hook SBControlCenterViewController
- (CGFloat)contentHeightForOrientation:(int)orientation {
  if (![(SpringBoard *)[%c(SpringBoard) sharedApplication] isLocked] && (orientation == 1 || orientation == 2)) {
    CSContainer.layer.hidden = NO;
    CSSeparator.layer.hidden = NO;
    return %orig+98;
  }
  else if ([(SpringBoard *)[%c(SpringBoard) sharedApplication] isLocked]) {
    CSContainer.layer.hidden = YES;
    CSSeparator.layer.hidden = YES;
    return %orig;
  }
  else {
    CSContainer.layer.hidden = NO;
    return %orig;
  }
}
%end
%hook SBControlCenterContentView
- (void)layoutSubviews {
  %orig;
  int currentOrientation = [(SpringBoard *)[objc_getClass("SpringBoard") sharedApplication] activeInterfaceOrientation];
  if (!CSContainer){
    CSContainer = [[[%c(SBControlCenterSectionView) alloc] initWithFrame:CGRectMake(0,self.frame.size.height-100,320,98)] autorelease];
  }
  [self addSubview:CSContainer];
  [CSContainer addSubview:[CSView sharedView]];
  if ([[CSView sharedView] currentIDS] == nil){
      [[CSView sharedView] layoutIconsWithIDS:[[%c(SBAppSliderController) sharedController] _beginAppListAccess]];
    }
  if (oldOrientation != currentOrientation) {
    [[CSView sharedView] layoutIconsWithIDS:[[CSView sharedView] currentIDS]];
  }
  oldOrientation = currentOrientation;
  if (!CSSeparator){
    CSSeparator = [[%c(SBControlCenterSeparatorView) alloc] initWithFrame:CGRectMake(0,CSContainer.frame.origin.y-4,320,1)];
    }    
    [self addSubview:CSSeparator];
  if (currentOrientation == 1 || currentOrientation == 2){
  self.quickLaunchSection.view.frame = CGRectMake(self.quickLaunchSection.view.frame.origin.x,self.quickLaunchSection.view.frame.origin.y-3,320,95);
  CSSeparator.layer.hidden = NO;
  CSContainer.frame = CGRectMake(0,self.frame.size.height-100,320,98);
  CSSeparator.frame = CGRectMake(0,CSContainer.frame.origin.y-4,320,1);
}
if (currentOrientation == 3 || currentOrientation == 4){
  self.quickLaunchSection.view.frame = CGRectMake(self.quickLaunchSection.view.frame.origin.x-98,self.quickLaunchSection.view.frame.origin.y,self.quickLaunchSection.view.frame.size.width,self.quickLaunchSection.view.frame.size.height);
  self.brightnessSection.view.frame = CGRectMake(self.brightnessSection.view.frame.origin.x,self.brightnessSection.view.frame.origin.y,self.brightnessSection.view.frame.size.width-100,self.brightnessSection.view.frame.size.height);
  self.mediaControlsSection.view.frame = CGRectMake(self.mediaControlsSection.view.frame.origin.x,self.mediaControlsSection.view.frame.origin.y,self.mediaControlsSection.view.frame.size.width-100,self.mediaControlsSection.view.frame.size.height);
  self.airplaySection.view.frame = CGRectMake(self.airplaySection.view.frame.origin.x,self.airplaySection.view.frame.origin.y,self.airplaySection.view.frame.size.width-100,self.airplaySection.view.frame.size.height);
  CSSeparator.layer.hidden = YES;
  CSContainer.frame = CGRectMake(self.frame.size.width - 100,0,98,320);
  for (UIView *view in self.subviews) {
    if ([view class] == [%c(SBControlCenterSeparatorView) class]){
      view.frame = CGRectMake(view.frame.origin.x,view.frame.origin.y,view.frame.size.width-100,view.frame.size.height);
    }
  }
}
}

- (void)dealloc {
  [CSContainer release];
  CSContainer = nil;
  [CSSeparator release];
  CSSeparator = nil;
  %orig;
}
%end
%end
%ctor {
  if (enable()) {
    %init(CSwitcher);
  };
}
