TapIt Corona SDK
================

a module for Ansca Corona to use TapIt ads on Corona applications.

Features;

   * Banner ads
   * Full screen interstitial ads (wall ads)
   * Alert ads

### Banner Ads Sample

```lua
local tapit = require("tapit")
tapit.requestBannerAds({zoneId=3644,x=0,y=0})
```

### Alert Ads Sample

```lua
local tapit = require("tapit")
tapit.requestAlertAds({zoneId=3644})
```

### Interstitial Ads Sample

```lua
local tapit = require("tapit")
tapit.requestInterstitialAds({zoneId=3644,x=0,y=0})
```

### Auto refresh banner ads
```lua
local tapit = require("tapit")
-- here we request a new banner ad at each 60 seconds.
timer.performWithDelay( 60*1000, function()
   tapit.requestBannerAds({zoneId=3644, x=0, y=0})
end, 0)
```

### Hide ads
```lua
tapit.hide()
```

GitHub repository and documentation

https://github.com/deniza/TapIt-Corona-SDK

Copyright by Deniz Aydinoglu

http://he2apps.com

Corona® SDK is registered trademark of Ansca® Inc. Ansca, the Ansca Logo, anscamobile.com are trademarks or registered trademarks of Ansca Inc.
