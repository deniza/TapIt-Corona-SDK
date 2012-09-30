------------------------------------------------------------
------------------------------------------------------------
-- TapIt Corona SDK
--
-- a module to use TapIt ads on your corona applications
-- by Deniz Aydinoglu
--
-- he2apps.com
--
-- GitHub repository and documentation:
-- https://github.com/deniza/TapIt-Corona-SDK
------------------------------------------------------------
------------------------------------------------------------

local json = require("json")

local userAgentIOS = "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_2 like Mac OS X; en) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8F190 Safari/6533.18.5"
local userAgentAndroid = "Mozilla/5.0 (Linux; U; Android 2.2; en-us; Nexus One Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"
local PLATFORM_IOS = 1
local PLATFORM_ANDROID = 2
local pluginIdentifier = "tapitcoronasdk-1.0"
local tapitAdServerUrl = "http://r.tapit.com/adrequest.php"
local dontScaleOnIPAD = true

local currentPlatform
local currentUserAgentStringEncoded
local runningOnIPAD
local viewportMetaTagForCurrentPlatform
local swapAlertButtons
local bannerOnClickHandler
local alertOnClickHandler
local interstitialOnClickHandler
local currentAdViewPosX
local currentAdViewPosY

local instance = {}

local function showAdAlert(message, clickUrl, callToAction, declineString, clickHandler)

    local function alertHandler(event)
        if event.action == "clicked" then
            
            local calltoActionIndex = 2
            if swapAlertButtons then
                calltoActionIndex = 1
            end

            if event.index == calltoActionIndex then

				if clickHandler then
					clickHandler(true)
				end            	

                system.openURL(clickUrl)
            else
                --just close alert window automatically

				if clickHandler then
					clickHandler(false)
				end            	

            end
        end
    end

    local buttons = { declineString, callToAction }
    if swapAlertButtons then
        buttons = { callToAction, declineString }
    end

    local alert = native.showAlert( "", message, buttons, alertHandler )

end

local function displayContentInWebPopup(x,y,contentWidth,contentHeight,contentHtml,clickHandler)
    
    local filename = "webview_tapitcoronasdk.html"
    local path = system.pathForFile( filename, system.TemporaryDirectory )
    local fhandle = io.open(path,"w")
    
    local newX = x
    local newY = y
    local newWidth = contentWidth
    local newHeight = contentHeight
    local scale = 1/display.contentScaleY

    if runningOnIPAD then
        
        if dontScaleOnIPAD then
            newWidth = newWidth/scale
            newHeight = newHeight/scale
        end

    end
    
    if currentPlatform == PLATFORM_ANDROID then

        -- Max scale for android is 2 (enforced above just in case), so adjust web popup if over 2. 
        if scale > 2 then
            scale = scale/2
            newWidth = (contentWidth/scale) + 1
            newHeight = (contentHeight/scale) + 2
            newX = x + (contentWidth - newWidth)/2
            newY = y + (contentHeight - newHeight)/2
        end
            
    end
 
    fhandle:write(contentHtml)
    io.close(fhandle)
    
    local function webPopupListener( event )

        if string.find(event.url, "file://", 1, false) == 1 then
            return true
        else

            timer.performWithDelay(10,function()
                
				if clickHandler then
					clickHandler(true)
				end            	

                system.openURL(event.url)
                native.cancelWebPopup()
            end)
            
        end
    end    
    
    -- fix scaling issues for ipad 3rd generation
    if 1/display.contentScaleY > 4 then
        newWidth = newWidth * 2
        newHeight = newHeight * 2
    end
    
    --cancel any opened web views first
    native.cancelWebPopup()

    local options = { hasBackground=false, baseUrl=system.TemporaryDirectory, urlRequest=webPopupListener } 
    native.showWebPopup( newX, newY, newWidth, newHeight, filename.."?"..os.time(), options)        
        
end

local function urlencode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str    
end

local function calculateViewportMetaTagForCurrentPlatform()

    -- Default for iPhone/iTouch
    local meta = "<meta name=\"viewport\" content=\"width=320; user-scalable=0;\"/>"
    local scale = 1/display.contentScaleY
 
    if currentPlatform == PLATFORM_ANDROID then
    
        meta = "<meta name=\"viewport\" content=\"width=320; initial-scale=1; minimum-scale=1; maximum-scale=2; user-scalable=0;\"/>"
        
    elseif runningOnIPAD then
        
        if scale > 4 then
            ---fix scaling issues for 'the new ipad'
            scale = scale * 0.5
        end
        
        local width = 320
        
        if dontScaleOnIPAD then
            scale = 1
            width = 160
        end
        
        meta = "<meta name=\"viewport\" content=\"width="..width.."; initial-scale=" .. scale .. 
                                                         "; minimum-scale=" .. scale ..
                                                          "; maximum-scale=" .. scale .. "; user-scalable=0;\"/>"
    end

    return meta

end

local function displayTapitResponseAsHtml(responseAsJson, clickHandler)

	local currentAdWidth = tonumber(responseAsJson.adWidth)
	local currentAdHeight = tonumber(responseAsJson.adHeight)

	responseAsJson.html = string.gsub(responseAsJson.html,'target=','target_disabled=')
	local htmlContent = '<html><head>'..viewportMetaTagForCurrentPlatform..'</head><body style="margin:0; padding:0; text-align:center">'..responseAsJson.html..'</body></html>'

	displayContentInWebPopup(currentAdViewPosX,currentAdViewPosY,currentAdWidth,currentAdHeight,htmlContent,clickHandler)

end

local function bannerAdListener(event)

	print("bannerAdListener:",event.response)

	local responseAsJson = json.decode(event.response)
    if responseAsJson.error then
	    print("banner ad not available: ", event.response)
	else
	    displayTapitResponseAsHtml(responseAsJson, bannerOnClickHandler)
	end

end

local function alertAdListener(event)

	print("alertAdListener:",event.response)

	local responseAsJson = json.decode(event.response)
    if responseAsJson.error then
	    print("alert ad not available: ", event.response)
	else

	    local clickUrl = responseAsJson.clickurl
	    local title = responseAsJson.adtitle
	    local callToAction = responseAsJson.calltoaction
	    local declineString = responseAsJson.declinestring

	    showAdAlert(title, clickUrl, callToAction, declineString, alertOnClickHandler)

	end
end

local function interstitialAdListener(event)

	print("interstitialAdListener:",event.response)

	local responseAsJson = json.decode(event.response)
    if responseAsJson.error then
	    print("interstitial ad not available: ", event.response)
	else
	    displayTapitResponseAsHtml(responseAsJson, interstitialOnClickHandler)
	end
end

local function requestHttp(url, requestParams, callBackFunction)

    local requestUri = url .. "?"

    for key,value in pairs(requestParams) do
        requestUri = requestUri .. key .. "=" .. value .. "&"
    end

	network.request(requestUri, "GET", callBackFunction)

end

local function initialize()

    if system.getInfo("platformName") == "Android" then        
        platform = PLATFORM_ANDROID
        currentUserAgentStringEncoded = urlencode(userAgentAndroid)
    else
        platform = PLATFORM_IOS
        currentUserAgentStringEncoded = urlencode(userAgentIOS)
    end

    if system.getInfo( "model" ) == "iPad" or system.getInfo( "model" ) == "iPad Simulator" then
        runningOnIPAD = true
    else
        runningOnIPAD = false
    end

    viewportMetaTagForCurrentPlatform = calculateViewportMetaTagForCurrentPlatform()

end

local function buildTapitParams(configParams)

    local tapitParams = {
        zone = configParams.zoneId,
        ua = currentUserAgentStringEncoded,
        format = "json",
        connection_speed = 1,
        plugin = pluginIdentifier,
    }

    return tapitParams

end

initialize()

------------------------------------------------------------
------------------------------------------------------------
--
-- Tapit Corona SDK public interface
--
------------------------------------------------------------
------------------------------------------------------------

local function requestBannerAds(configParams)

    local requestParams = buildTapitParams(configParams)
    bannerOnClickHandler = configParams.onClick or nil
    currentAdViewPosX = configParams.x or 0
    currentAdViewPosY = configParams.y or 0

	requestHttp(tapitAdServerUrl, requestParams, bannerAdListener)

end
instance.requestBannerAds = requestBannerAds

local function requestAlertAds(configParams)

    local requestParams = buildTapitParams(configParams)
    requestParams.adtype = 10

    swapAlertButtons = configParams.swapButtons or false
    alertOnClickHandler = configParams.onClick or nil

	requestHttp(tapitAdServerUrl, requestParams, alertAdListener)

end
instance.requestAlertAds = requestAlertAds

local function requestInterstitialAds(configParams)

    local requestParams = buildTapitParams(configParams)
    requestParams.adtype = 2

    interstitialOnClickHandler = configParams.onClick or nil
    currentAdViewPosX = configParams.x or 0
    currentAdViewPosY = configParams.y or 0

	requestHttp(tapitAdServerUrl, requestParams, interstitialAdListener)

end
instance.requestInterstitialAds = requestInterstitialAds

local function hide()
    native.cancelWebPopup()
end
instance.hide = hide

return instance