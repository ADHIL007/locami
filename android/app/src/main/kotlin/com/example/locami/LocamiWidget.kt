package com.example.locami

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.*
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.app.PendingIntent
import android.content.Intent
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.PI

class LocamiWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: android.content.SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.locami_widget).apply {
                val distance = widgetData.getString("distance", "-- km")
                val speedVal = widgetData.getString("speed", "0")?.toIntOrNull() ?: 0
                val isTracking = widgetData.getBoolean("is_tracking", false)
                val currentLoc = widgetData.getString("current_loc", "Finding location...")
                val destName = widgetData.getString("dest_name", "Destination")
                val progressVal = widgetData.getInt("progress", 0)
                val statusInfo = widgetData.getString("status_info", "--")
                val alertDist = widgetData.getString("alert_dist", "500m")

                setTextViewText(R.id.widget_distance_value, distance)
                setTextViewText(R.id.widget_current_loc, currentLoc)
                setTextViewText(R.id.widget_dest_name, "to $destName")
                setTextViewText(R.id.widget_status_label, statusInfo)
                setTextViewText(R.id.widget_alert_dist, "Alert within $alertDist")
                
                // Draw Gauge Bitmap
                val gaugeBitmap = drawCircularGauge(context, speedVal)
                setImageViewBitmap(R.id.widget_gauge_img, gaugeBitmap)

                // Draw Linear Progress Bitmap
                val progressBitmap = drawLinearProgress(context, progressVal)
                setImageViewBitmap(R.id.widget_progress_img, progressBitmap)

                if (isTracking) {
                    setViewVisibility(R.id.top_section, View.VISIBLE)
                    setViewVisibility(R.id.progress_section, View.VISIBLE)
                    setViewVisibility(R.id.widget_button, View.VISIBLE)
                    setTextViewText(R.id.widget_button_text, "STOP ALERT")
                    setInt(R.id.widget_button, "setBackgroundResource", R.drawable.widget_button_bg)
                } else {
                    setViewVisibility(R.id.top_section, View.VISIBLE)
                    setTextViewText(R.id.widget_current_loc, "Ready to start a new trip")
                    setTextViewText(R.id.widget_distance_value, "Locami")
                    setTextViewText(R.id.widget_dest_name, "Select a destination")
                    setViewVisibility(R.id.progress_section, View.INVISIBLE)
                    setViewVisibility(R.id.widget_button, View.VISIBLE)
                    setTextViewText(R.id.widget_button_text, "START TRIP")
                    setInt(R.id.widget_button, "setBackgroundResource", R.drawable.widget_button_accent)
                    setTextViewText(R.id.widget_status_label, "Ready for next adventure")
                }

                // Launch App on click
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                setOnClickPendingIntent(R.id.widget_title, pendingIntent)
                setOnClickPendingIntent(R.id.widget_button, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun drawCircularGauge(context: Context, speed: Int): Bitmap {
        val density = context.resources.displayMetrics.density
        val size = (80 * density).toInt()
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val radius = (size / 2f) - (8 * density)
        val rect = RectF(size / 2f - radius, size / 2f - radius, size / 2f + radius, size / 2f + radius)
        
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 3 * density
            strokeCap = Paint.Cap.ROUND
        }

        // Background Arc
        paint.color = Color.parseColor("#15FFFFFF")
        canvas.drawArc(rect, 135f, 270f, false, paint)

        // Active Speed Arc
        paint.color = Color.parseColor("#C62828")
        val sweepAngle = (speed.toFloat() / 120f).coerceIn(0f, 1f) * 270f
        canvas.drawArc(rect, 135f, sweepAngle, false, paint)

        // Tick marks
        paint.strokeWidth = 1 * density
        paint.color = Color.parseColor("#20FFFFFF")
        val tickCount = 20
        for (i in 0..tickCount) {
            val angle = (135f + (270f * i / tickCount)) * (PI.toFloat() / 180f)
            val outerX = size / 2f + (radius + 4 * density) * cos(angle)
            val outerY = size / 2f + (radius + 4 * density) * sin(angle)
            val innerX = size / 2f + (radius - 2 * density) * cos(angle)
            val innerY = size / 2f + (radius - 2 * density) * sin(angle)
            canvas.drawLine(innerX, innerY, outerX, outerY, paint)
        }

        // Speed Text
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            color = Color.WHITE
            textSize = 26 * density
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        canvas.drawText(speed.toString(), size / 2f, size / 2f + 6 * density, textPaint)

        // Unit Text
        textPaint.textSize = 8 * density
        textPaint.color = Color.parseColor("#66FFFFFF")
        canvas.drawText("km/h", size / 2f, size / 2f + 18 * density, textPaint)

        return bitmap
    }

    private fun drawLinearProgress(context: Context, progress: Int): Bitmap {
        val density = context.resources.displayMetrics.density
        val width = (300 * density).toInt().coerceAtLeast(1)
        val height = (14 * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val rect = RectF(0f, height / 2f - 2 * density, width.toFloat(), height / 2f + 2 * density)
        
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
        }

        // Track background
        paint.color = Color.parseColor("#15FFFFFF")
        canvas.drawRoundRect(rect, 2 * density, 2 * density, paint)

        // Active progress
        paint.color = Color.parseColor("#C62828")
        val progressWidth = (progress.toFloat() / 100f) * width
        val activeRect = RectF(0f, height / 2f - 2 * density, progressWidth, height / 2f + 2 * density)
        canvas.drawRoundRect(activeRect, 2 * density, 2 * density, paint)

        // Progress Thumb (Circle)
        paint.color = Color.WHITE
        val thumbX = progressWidth.coerceIn(4 * density, width.toFloat() - 4 * density)
        canvas.drawCircle(thumbX, height / 2f, 5 * density, paint)

        return bitmap
    }
}
