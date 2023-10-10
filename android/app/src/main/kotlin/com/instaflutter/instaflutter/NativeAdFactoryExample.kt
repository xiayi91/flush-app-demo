package com.instaflutter.instaflutter

import android.annotation.SuppressLint
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import com.instaflutter.instaflutter.android.R
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class NativeAdFactoryExample(private val layoutInflater: LayoutInflater) :
    NativeAdFactory {
    @SuppressLint("InflateParams")
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String, Any>
    ): NativeAdView {
        val adView =
            layoutInflater.inflate(R.layout.my_native_ad, null) as NativeAdView

        // Set the media view.

        // Set the media view.
        adView.mediaView = adView.findViewById<View>(R.id.ad_media) as MediaView

        // Set other ad assets.

        // Set other ad assets.
        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById(R.id.ad_app_icon)
        adView.priceView = adView.findViewById(R.id.ad_price)
        adView.starRatingView = adView.findViewById(R.id.ad_stars)
        adView.storeView = adView.findViewById(R.id.ad_store)
        adView.advertiserView = adView.findViewById(R.id.ad_advertiser)

        // The headline and mediaContent are guaranteed to be in every NativeAd.

        // The headline and mediaContent are guaranteed to be in every NativeAd.
        (adView.headlineView as TextView).text = nativeAd.headline
        adView.mediaView?.setMediaContent(nativeAd.mediaContent!!)

        // These assets aren't guaranteed to be in every NativeAd, so it's important to
        // check before trying to display them.

        // These assets aren't guaranteed to be in every NativeAd, so it's important to
        // check before trying to display them.
        if (nativeAd.body == null) {
            adView.bodyView?.visibility = View.INVISIBLE
        } else {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as TextView).text = nativeAd.body
        }

        if (nativeAd.callToAction == null) {
            adView.callToActionView?.visibility = View.INVISIBLE
        } else {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as Button).text = nativeAd.callToAction
        }

        if (nativeAd.icon == null) {
            adView.iconView?.visibility = View.GONE
        } else {
            (adView.iconView as ImageView).setImageDrawable(nativeAd.icon?.drawable)
            adView.iconView?.visibility = View.VISIBLE
        }

        if (nativeAd.price == null) {
            adView.priceView?.visibility = View.INVISIBLE
        } else {
            adView.priceView?.visibility = View.VISIBLE
            (adView.priceView as TextView).text = nativeAd.price
        }

        if (nativeAd.store == null) {
            adView.storeView?.visibility = View.INVISIBLE
        } else {
            adView.storeView?.visibility = View.VISIBLE
            (adView.storeView as TextView).text = nativeAd.store
        }

        if (nativeAd.starRating == null) {
            adView.starRatingView?.visibility = View.INVISIBLE
        } else {
            (adView.starRatingView as RatingBar).rating =
                nativeAd.starRating?.toFloat() ?: 1.0f
            adView.starRatingView?.visibility = View.VISIBLE
        }

        if (nativeAd.advertiser == null) {
            adView.advertiserView?.visibility = View.INVISIBLE
        } else {
            adView.advertiserView?.visibility = View.VISIBLE
            (adView.advertiserView as TextView).text = nativeAd.advertiser
        }

        // This method tells the Google Mobile Ads SDK that you have finished populating your
        // native ad view with this native ad.
        adView.setNativeAd(nativeAd)

        return adView
    }
}