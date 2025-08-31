package com.follow.clash.common

import android.content.Intent
import android.os.IBinder
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import java.util.concurrent.atomic.AtomicBoolean

class ServiceDelegate<T>(
    private val intent: Intent,
    private val onServiceDisconnected: (() -> Unit)? = null,
    private val interfaceCreator: (IBinder) -> T,
) : CoroutineScope by CoroutineScope(SupervisorJob() + Dispatchers.Default) {

    private val _bindingState = AtomicBoolean(false)

    private val _service = MutableStateFlow<T?>(null)

    val service: StateFlow<T?> = _service
    private var job: Job? = null
    private fun handleBind(binder: IBinder?) {
        when (binder != null) {
            true -> {
                _service.value = interfaceCreator(binder)
            }

            false -> {
                unbind()
                onServiceDisconnected?.invoke()
            }
        }
    }

    private fun bind() {
        if (_bindingState.compareAndSet(false, true)) {
            job = launch {
                GlobalState.application.bindServiceFlow<IBinder>(intent).collect { it ->
                    handleBind(it)
                }
            }
        }
    }

    suspend fun <R> useService(
        timeoutMillis: Long = 5000,
        block: (T) -> R
    ): R? {
        bind()
        _service.value?.let { return block(it) }
        return withTimeoutOrNull(timeoutMillis) {
            _service.filterNotNull().first().let(block)
        }
    }

    fun unbind() {
        if (_bindingState.compareAndSet(true, false)) {
            _service.value = null
            job?.cancel()
            job = null
        }
    }
}