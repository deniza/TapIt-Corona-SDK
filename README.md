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

-- you can also call the function below to close an already opened interstitial ads window
-- tapit.closeIntersitialAds()

```

GitHub repository and documentation

https://github.com/deniza/TapIt-Corona-SDK

Copyright by Deniz Aydinoglu

http://he2apps.com

Corona® SDK is registered trademark of Ansca® Inc. Ansca, the Ansca Logo, anscamobile.com are trademarks or registered trademarks of Ansca Inc.
