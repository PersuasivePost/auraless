package com.example.mini

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

class MindfulDelayActivity : Activity() {
    private var timer: CountDownTimer? = null
    private var timerFinished = false
    private var remainingMillis: Long = 0L
    private var timerRunning: Boolean = false

    private lateinit var countdownText: TextView
    private lateinit var appLabelText: TextView
    private lateinit var buttonsLayout: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val delay = intent.getIntExtra("mindful_delay_seconds", 30)
        val targetPkg = intent.getStringExtra("packageName")

        // Build UI programmatically
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(40, 80, 40, 80)
        }

        appLabelText = TextView(this).apply {
            textSize = 20f
            gravity = Gravity.CENTER
            text = getAppLabel(targetPkg)
        }

        countdownText = TextView(this).apply {
            textSize = 32f
            gravity = Gravity.CENTER
            text = "Please wait..."
        }

        buttonsLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            visibility = View.GONE
        }

        val openBtn = Button(this).apply {
            text = "Open App"
            setOnClickListener {
                if (targetPkg != null) {
                    val pm = packageManager
                    val launch = pm.getLaunchIntentForPackage(targetPkg)
                    if (launch != null) {
                        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(launch)
                        finish()
                    } else {
                        Toast.makeText(this@MindfulDelayActivity, "Cannot open app", Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }

        val backBtn = Button(this).apply {
            text = "Back to Launcher"
            setOnClickListener {
                finish()
            }
        }

        // layout params
        val btnLp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        btnLp.setMargins(20, 0, 20, 0)
        buttonsLayout.addView(openBtn, btnLp)
        buttonsLayout.addView(backBtn, btnLp)

        // add views
        root.addView(appLabelText)
        root.addView(countdownText)
        root.addView(buttonsLayout)

        setContentView(root)

        // restore state if available
        if (savedInstanceState != null) {
            timerFinished = savedInstanceState.getBoolean("timerFinished", false)
            remainingMillis = savedInstanceState.getLong("remainingMillis", (delay * 1000).toLong())
        } else {
            remainingMillis = (delay * 1000).toLong()
        }

        if (timerFinished) {
            countdownText.visibility = View.GONE
            buttonsLayout.visibility = View.VISIBLE
        } else {
            startTimer(remainingMillis)
        }
    }

    private fun startTimer(ms: Long) {
        timer?.cancel()
        timer = object : CountDownTimer(ms, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                remainingMillis = millisUntilFinished
                val s = millisUntilFinished / 1000
                countdownText.text = "Mindful delay: $s s"
                timerRunning = true
            }

            override fun onFinish() {
                timerFinished = true
                timerRunning = false
                countdownText.visibility = View.GONE
                buttonsLayout.visibility = View.VISIBLE
            }
        }
        timer?.start()
        timerRunning = true
    }

    private fun getAppLabel(pkg: String?): String {
        if (pkg == null) return "Blocked app"
        return try {
            val pm = packageManager
            val ai = pm.getApplicationInfo(pkg, 0)
            pm.getApplicationLabel(ai).toString()
        } catch (e: Exception) {
            pkg
        }
    }

    override fun onBackPressed() {
        if (!timerFinished) {
            // ignore back presses while timer is running
            return
        }
        super.onBackPressed()
    }

    override fun onDestroy() {
        super.onDestroy()
        timer?.cancel()
    }

    override fun onPause() {
        super.onPause()
        // pause the countdown and remember remaining time
        if (timerRunning) {
            timer?.cancel()
            timerRunning = false
            // remainingMillis already updated in onTick
        }
    }

    override fun onResume() {
        super.onResume()
        // resume timer if it wasn't finished
        if (!timerFinished && !timerRunning) {
            // if remainingMillis is zero, nothing to do
            if (remainingMillis > 0L) {
                startTimer(remainingMillis)
            }
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean("timerFinished", timerFinished)
        outState.putLong("remainingMillis", remainingMillis)
    }
}
