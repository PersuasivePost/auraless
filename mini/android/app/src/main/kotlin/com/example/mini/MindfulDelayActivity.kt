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

        timer = object : CountDownTimer((delay * 1000).toLong(), 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val s = millisUntilFinished / 1000
                countdownText.text = "Mindful delay: $s s"
            }

            override fun onFinish() {
                timerFinished = true
                countdownText.visibility = View.GONE
                buttonsLayout.visibility = View.VISIBLE
            }
        }
        timer?.start()
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
}
