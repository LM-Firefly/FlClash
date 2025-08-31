package com.follow.clash.common

import android.content.Intent
import android.os.IBinder
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicBoolean

class ServiceDelegate<T>(
    private val intent: Intent,
    private val onServiceDisconnected: (() -> Unit)? = null,
    private val onServiceCrash: (() -> Unit)? = null,
    private val interfaceCreator: (IBinder) -> T,
) : CoroutineScope by CoroutineScope(SupervisorJob() + Dispatchers.Default) {

    private val bindingState = AtomicBoolean(false)

    private val _service = MutableStateFlow<T?>(null)

    val service: StateFlow<T?> = _service
    private var job: Job? = null
    private fun handleBindEvent(event: BindServiceEvent<IBinder>) {
        when (event) {
            is BindServiceEvent.Connected -> {
                _service.value = event.binder.let(interfaceCreator)
            }

            is BindServiceEvent.Disconnected -> {
                _service.value = null
                onServiceDisconnected?.invoke()
            }

            is BindServiceEvent.Crashed -> {
                _service.value = null
                onServiceCrash?.invoke()
            }
        }
    }

    fun bind() {
        if (bindingState.compareAndSet(false, true)) {
            job = launch {
                GlobalState.application.bindServiceFlow<IBinder>(intent).collect { it ->
                    handleBindEvent(it)
                }
            }
        }
    }

    suspend inline fun <R> useService(
        retries: Int = 10, delayMillis: Long = 200, crossinline block: (T) -> R
    ) {
        flow {
            repeat(retries + 1) {
                service.value?.let { emit(it) }
                delay(delayMillis)
            }
        }.firstOrNull()?.let(block)
    }

    fun unbind() {
        if (bindingState.compareAndSet(true, false)) {
            _service.value = null
            job?.cancel()
            job = null
        }
    }
}