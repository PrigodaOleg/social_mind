window.wasm_bindgen = (function(exports) {
    let script_src;
    if (typeof document !== 'undefined' && document.currentScript !== null) {
        script_src = new URL(document.currentScript.src, location.href).toString();
    }

    function __wbg_get_imports() {
        const import0 = {
            __proto__: null,
            __wbg_Window_70131fc0c91e4b3c: function(arg0) {
                const ret = getObject(arg0).Window;
                return addHeapObject(ret);
            },
            __wbg_WorkerGlobalScope_601c48015b8cc78e: function(arg0) {
                const ret = getObject(arg0).WorkerGlobalScope;
                return addHeapObject(ret);
            },
            __wbg___wbindgen_debug_string_5398f5bb970e0daa: function(arg0, arg1) {
                const ret = debugString(getObject(arg1));
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg___wbindgen_is_function_3c846841762788c1: function(arg0) {
                const ret = typeof(getObject(arg0)) === 'function';
                return ret;
            },
            __wbg___wbindgen_is_null_0b605fc6b167c56f: function(arg0) {
                const ret = getObject(arg0) === null;
                return ret;
            },
            __wbg___wbindgen_is_undefined_52709e72fb9f179c: function(arg0) {
                const ret = getObject(arg0) === undefined;
                return ret;
            },
            __wbg___wbindgen_number_get_34bb9d9dcfa21373: function(arg0, arg1) {
                const obj = getObject(arg1);
                const ret = typeof(obj) === 'number' ? obj : undefined;
                getDataViewMemory0().setFloat64(arg0 + 8 * 1, isLikeNone(ret) ? 0 : ret, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, !isLikeNone(ret), true);
            },
            __wbg___wbindgen_string_get_395e606bd0ee4427: function(arg0, arg1) {
                const obj = getObject(arg1);
                const ret = typeof(obj) === 'string' ? obj : undefined;
                var ptr1 = isLikeNone(ret) ? 0 : passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
                var len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg___wbindgen_throw_6ddd609b62940d55: function(arg0, arg1) {
                throw new Error(getStringFromWasm0(arg0, arg1));
            },
            __wbg__wbg_cb_unref_6b5b6b8576d35cb1: function(arg0) {
                getObject(arg0)._wbg_cb_unref();
            },
            __wbg_abort_60dcb252ae0031fc: function() { return handleError(function (arg0) {
                getObject(arg0).abort();
            }, arguments); },
            __wbg_add_fe24b809ecd53906: function(arg0, arg1) {
                const ret = getObject(arg0).add(getObject(arg1));
                return addHeapObject(ret);
            },
            __wbg_bound_4e343b4fbe5419fa: function() { return handleError(function (arg0, arg1, arg2, arg3) {
                const ret = IDBKeyRange.bound(getObject(arg0), getObject(arg1), arg2 !== 0, arg3 !== 0);
                return addHeapObject(ret);
            }, arguments); },
            __wbg_buffer_60b8043cd926067d: function(arg0) {
                const ret = getObject(arg0).buffer;
                return addHeapObject(ret);
            },
            __wbg_byteLength_607b856aa6c5a508: function(arg0) {
                const ret = getObject(arg0).byteLength;
                return ret;
            },
            __wbg_byteOffset_b26b63681c83856c: function(arg0) {
                const ret = getObject(arg0).byteOffset;
                return ret;
            },
            __wbg_clear_1885f7bf35006b0c: function() { return handleError(function (arg0) {
                const ret = getObject(arg0).clear();
                return addHeapObject(ret);
            }, arguments); },
            __wbg_commit_e9c1332714c53826: function() { return handleError(function (arg0) {
                getObject(arg0).commit();
            }, arguments); },
            __wbg_createObjectStore_4709de9339ffc6c0: function() { return handleError(function (arg0, arg1, arg2, arg3) {
                const ret = getObject(arg0).createObjectStore(getStringFromWasm0(arg1, arg2), getObject(arg3));
                return addHeapObject(ret);
            }, arguments); },
            __wbg_createSyncAccessHandle_b7143219a305a2ce: function(arg0) {
                const ret = getObject(arg0).createSyncAccessHandle();
                return addHeapObject(ret);
            },
            __wbg_delete_21833c7fd604a47f: function(arg0, arg1) {
                const ret = getObject(arg0).delete(getObject(arg1));
                return ret;
            },
            __wbg_delete_40db93c05c546fb9: function() { return handleError(function (arg0, arg1) {
                const ret = getObject(arg0).delete(getObject(arg1));
                return addHeapObject(ret);
            }, arguments); },
            __wbg_delete_cf083e3bbb9857fe: function(arg0, arg1) {
                const ret = getObject(arg0).delete(getObject(arg1));
                return ret;
            },
            __wbg_done_08ce71ee07e3bd17: function(arg0) {
                const ret = getObject(arg0).done;
                return ret;
            },
            __wbg_entries_310f5926c32b5bcb: function(arg0) {
                const ret = getObject(arg0).entries();
                return addHeapObject(ret);
            },
            __wbg_error_74898554122344a8: function() { return handleError(function (arg0) {
                const ret = getObject(arg0).error;
                return isLikeNone(ret) ? 0 : addHeapObject(ret);
            }, arguments); },
            __wbg_fill_8c98ef3fd18c2e5c: function(arg0, arg1, arg2, arg3) {
                const ret = getObject(arg0).fill(arg1, arg2 >>> 0, arg3 >>> 0);
                return addHeapObject(ret);
            },
            __wbg_flush_1eca046e0ff7c399: function() { return handleError(function (arg0) {
                getObject(arg0).flush();
            }, arguments); },
            __wbg_from_4bdf88943703fd48: function(arg0) {
                const ret = Array.from(getObject(arg0));
                return addHeapObject(ret);
            },
            __wbg_getAll_690f659b57ae2d51: function() { return handleError(function (arg0) {
                const ret = getObject(arg0).getAll();
                return addHeapObject(ret);
            }, arguments); },
            __wbg_getAll_a959860fbb7a424a: function() { return handleError(function (arg0, arg1) {
                const ret = getObject(arg0).getAll(getObject(arg1));
                return addHeapObject(ret);
            }, arguments); },
            __wbg_getDate_fbf9a2247e954082: function(arg0) {
                const ret = getObject(arg0).getDate();
                return ret;
            },
            __wbg_getDay_2287a9ab7ef27b82: function(arg0) {
                const ret = getObject(arg0).getDay();
                return ret;
            },
            __wbg_getDirectoryHandle_5f0ee1df58525717: function(arg0, arg1, arg2, arg3) {
                const ret = getObject(arg0).getDirectoryHandle(getStringFromWasm0(arg1, arg2), getObject(arg3));
                return addHeapObject(ret);
            },
            __wbg_getDirectory_2406d369de179ff0: function(arg0) {
                const ret = getObject(arg0).getDirectory();
                return addHeapObject(ret);
            },
            __wbg_getFileHandle_b85805519dc63efa: function(arg0, arg1, arg2, arg3) {
                const ret = getObject(arg0).getFileHandle(getStringFromWasm0(arg1, arg2), getObject(arg3));
                return addHeapObject(ret);
            },
            __wbg_getFullYear_f6d84c054eee1543: function(arg0) {
                const ret = getObject(arg0).getFullYear();
                return ret;
            },
            __wbg_getHours_391d39cf9970a985: function(arg0) {
                const ret = getObject(arg0).getHours();
                return ret;
            },
            __wbg_getMinutes_c6b51adde167b27d: function(arg0) {
                const ret = getObject(arg0).getMinutes();
                return ret;
            },
            __wbg_getMonth_884df91d4880455c: function(arg0) {
                const ret = getObject(arg0).getMonth();
                return ret;
            },
            __wbg_getSeconds_53838367bdfd2269: function(arg0) {
                const ret = getObject(arg0).getSeconds();
                return ret;
            },
            __wbg_getSize_0a16c5e2524d34aa: function() { return handleError(function (arg0) {
                const ret = getObject(arg0).getSize();
                return ret;
            }, arguments); },
            __wbg_getTime_1dad7b5386ddd2d9: function(arg0) {
                const ret = getObject(arg0).getTime();
                return ret;
            },
            __wbg_getTimezoneOffset_639bcf2dde21158b: function(arg0) {
                const ret = getObject(arg0).getTimezoneOffset();
                return ret;
            },
            __wbg_getUint32_d3eb02a67faa790e: function(arg0, arg1) {
                const ret = getObject(arg0).getUint32(arg1 >>> 0);
                return ret;
            },
            __wbg_get_10ee87d86a58fb49: function(arg0, arg1) {
                const ret = getObject(arg0).get(getObject(arg1));
                return addHeapObject(ret);
            },
            __wbg_get_3ef1eba1850ade27: function() { return handleError(function (arg0, arg1) {
                const ret = Reflect.get(getObject(arg0), getObject(arg1));
                return addHeapObject(ret);
            }, arguments); },
            __wbg_get_a8ee5c45dabc1b3b: function(arg0, arg1) {
                const ret = getObject(arg0)[arg1 >>> 0];
                return addHeapObject(ret);
            },
            __wbg_get_index_87179971b8d350e4: function(arg0, arg1) {
                const ret = getObject(arg0)[arg1 >>> 0];
                return ret;
            },
            __wbg_get_unchecked_329cfe50afab7352: function(arg0, arg1) {
                const ret = getObject(arg0)[arg1 >>> 0];
                return addHeapObject(ret);
            },
            __wbg_global_e30ac0b7684506d0: function(arg0) {
                const ret = getObject(arg0).global;
                return addHeapObject(ret);
            },
            __wbg_has_c89137ef83880587: function(arg0, arg1) {
                const ret = getObject(arg0).has(getObject(arg1));
                return ret;
            },
            __wbg_indexedDB_2ae2128d487c6ebc: function() { return handleError(function (arg0) {
                const ret = getObject(arg0).indexedDB;
                return isLikeNone(ret) ? 0 : addHeapObject(ret);
            }, arguments); },
            __wbg_indexedDB_a2139150e2ea2a08: function() { return handleError(function (arg0) {
                const ret = getObject(arg0).indexedDB;
                return isLikeNone(ret) ? 0 : addHeapObject(ret);
            }, arguments); },
            __wbg_indexedDB_c83feb7151bbde52: function() { return handleError(function (arg0) {
                const ret = getObject(arg0).indexedDB;
                return isLikeNone(ret) ? 0 : addHeapObject(ret);
            }, arguments); },
            __wbg_instanceof_DomException_2bdcf7791a2d7d09: function(arg0) {
                let result;
                try {
                    result = getObject(arg0) instanceof DOMException;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                return ret;
            },
            __wbg_instanceof_Error_4691a5b466e32a80: function(arg0) {
                let result;
                try {
                    result = getObject(arg0) instanceof Error;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                return ret;
            },
            __wbg_instanceof_IdbDatabase_5f436cc89cc07f14: function(arg0) {
                let result;
                try {
                    result = getObject(arg0) instanceof IDBDatabase;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                return ret;
            },
            __wbg_instanceof_IdbRequest_6a0e24572d4f1d46: function(arg0) {
                let result;
                try {
                    result = getObject(arg0) instanceof IDBRequest;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                return ret;
            },
            __wbg_instanceof_WorkerGlobalScope_de6976d00cb213c6: function(arg0) {
                let result;
                try {
                    result = getObject(arg0) instanceof WorkerGlobalScope;
                } catch (_) {
                    result = false;
                }
                const ret = result;
                return ret;
            },
            __wbg_isArray_33b91feb269ff46e: function(arg0) {
                const ret = Array.isArray(getObject(arg0));
                return ret;
            },
            __wbg_keys_1277d44a9e3749ff: function(arg0) {
                const ret = getObject(arg0).keys();
                return addHeapObject(ret);
            },
            __wbg_length_15d3fc853a68bbbc: function(arg0) {
                const ret = getObject(arg0).length;
                return ret;
            },
            __wbg_length_b3416cf66a5452c8: function(arg0) {
                const ret = getObject(arg0).length;
                return ret;
            },
            __wbg_length_ea16607d7b61445b: function(arg0) {
                const ret = getObject(arg0).length;
                return ret;
            },
            __wbg_lowerBound_7dd256f30bc73b4e: function() { return handleError(function (arg0, arg1) {
                const ret = IDBKeyRange.lowerBound(getObject(arg0), arg1 !== 0);
                return addHeapObject(ret);
            }, arguments); },
            __wbg_message_00d63f20c41713dd: function(arg0) {
                const ret = getObject(arg0).message;
                return addHeapObject(ret);
            },
            __wbg_message_e959edc81e4b6cb7: function(arg0, arg1) {
                const ret = getObject(arg1).message;
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg_name_7a3bbd030d0afa16: function(arg0, arg1) {
                const ret = getObject(arg1).name;
                const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
                const len1 = WASM_VECTOR_LEN;
                getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
                getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
            },
            __wbg_navigator_583ffd4fc14c0f7a: function(arg0) {
                const ret = getObject(arg0).navigator;
                return addHeapObject(ret);
            },
            __wbg_new_0_1dcafdf5e786e876: function() {
                const ret = new Date();
                return addHeapObject(ret);
            },
            __wbg_new_49d5571bd3f0c4d4: function() {
                const ret = new Map();
                return addHeapObject(ret);
            },
            __wbg_new_94350226ad30c16b: function(arg0, arg1, arg2) {
                const ret = new DataView(getObject(arg0), arg1 >>> 0, arg2 >>> 0);
                return addHeapObject(ret);
            },
            __wbg_new_ab79df5bd7c26067: function() {
                const ret = new Object();
                return addHeapObject(ret);
            },
            __wbg_new_d15cb560a6a0e5f0: function(arg0, arg1) {
                const ret = new Error(getStringFromWasm0(arg0, arg1));
                return addHeapObject(ret);
            },
            __wbg_new_fd94ca5c9639abd2: function(arg0) {
                const ret = new Date(getObject(arg0));
                return addHeapObject(ret);
            },
            __wbg_new_from_slice_22da9388ac046e50: function(arg0, arg1) {
                const ret = new Uint8Array(getArrayU8FromWasm0(arg0, arg1));
                return addHeapObject(ret);
            },
            __wbg_new_typed_5762eff9a201de38: function() {
                const ret = new Set();
                return addHeapObject(ret);
            },
            __wbg_new_typed_bccac67128ed885a: function() {
                const ret = new Array();
                return addHeapObject(ret);
            },
            __wbg_new_with_length_825018a1616e9e55: function(arg0) {
                const ret = new Uint8Array(arg0 >>> 0);
                return addHeapObject(ret);
            },
            __wbg_new_with_year_month_day_82496ee7686a68d8: function(arg0, arg1, arg2) {
                const ret = new Date(arg0 >>> 0, arg1, arg2);
                return addHeapObject(ret);
            },
            __wbg_next_11b99ee6237339e3: function() { return handleError(function (arg0) {
                const ret = getObject(arg0).next();
                return addHeapObject(ret);
            }, arguments); },
            __wbg_next_eca3bb2f1a45eec9: function() { return handleError(function (arg0) {
                const ret = getObject(arg0).next();
                return addHeapObject(ret);
            }, arguments); },
            __wbg_objectStore_f314ab152a5c7bd0: function() { return handleError(function (arg0, arg1, arg2) {
                const ret = getObject(arg0).objectStore(getStringFromWasm0(arg1, arg2));
                return addHeapObject(ret);
            }, arguments); },
            __wbg_open_e7a9d3d6344572f6: function() { return handleError(function (arg0, arg1, arg2, arg3) {
                const ret = getObject(arg0).open(getStringFromWasm0(arg1, arg2), arg3 >>> 0);
                return addHeapObject(ret);
            }, arguments); },
            __wbg_prototypesetcall_d62e5099504357e6: function(arg0, arg1, arg2) {
                Uint8Array.prototype.set.call(getArrayU8FromWasm0(arg0, arg1), getObject(arg2));
            },
            __wbg_push_e87b0e732085a946: function(arg0, arg1) {
                const ret = getObject(arg0).push(getObject(arg1));
                return ret;
            },
            __wbg_put_ae369598c083f1f5: function() { return handleError(function (arg0, arg1) {
                const ret = getObject(arg0).put(getObject(arg1));
                return addHeapObject(ret);
            }, arguments); },
            __wbg_queueMicrotask_0c399741342fb10f: function(arg0) {
                const ret = getObject(arg0).queueMicrotask;
                return addHeapObject(ret);
            },
            __wbg_queueMicrotask_a082d78ce798393e: function(arg0) {
                queueMicrotask(getObject(arg0));
            },
            __wbg_random_5bb86cae65a45bf6: function() {
                const ret = Math.random();
                return ret;
            },
            __wbg_read_0285869b4fd131af: function() { return handleError(function (arg0, arg1, arg2, arg3) {
                const ret = getObject(arg0).read(getArrayU8FromWasm0(arg1, arg2), getObject(arg3));
                return ret;
            }, arguments); },
            __wbg_read_f0bbcacfbadb350b: function() { return handleError(function (arg0, arg1, arg2) {
                const ret = getObject(arg0).read(getObject(arg1), getObject(arg2));
                return ret;
            }, arguments); },
            __wbg_readyState_57fa0866477cc0c4: function(arg0) {
                const ret = getObject(arg0).readyState;
                return (__wbindgen_enum_IdbRequestReadyState.indexOf(ret) + 1 || 3) - 1;
            },
            __wbg_resolve_ae8d83246e5bcc12: function(arg0) {
                const ret = Promise.resolve(getObject(arg0));
                return addHeapObject(ret);
            },
            __wbg_result_c5baa2d3d690a01a: function() { return handleError(function (arg0) {
                const ret = getObject(arg0).result;
                return addHeapObject(ret);
            }, arguments); },
            __wbg_setUint32_f5040a0d9acfdee0: function(arg0, arg1, arg2) {
                getObject(arg0).setUint32(arg1 >>> 0, arg2 >>> 0);
            },
            __wbg_set_7eaa4f96924fd6b3: function() { return handleError(function (arg0, arg1, arg2) {
                const ret = Reflect.set(getObject(arg0), getObject(arg1), getObject(arg2));
                return ret;
            }, arguments); },
            __wbg_set_8c0b3ffcf05d61c2: function(arg0, arg1, arg2) {
                getObject(arg0).set(getArrayU8FromWasm0(arg1, arg2));
            },
            __wbg_set_at_e227be75df7f9abf: function(arg0, arg1) {
                getObject(arg0).at = arg1;
            },
            __wbg_set_bf7251625df30a02: function(arg0, arg1, arg2) {
                const ret = getObject(arg0).set(getObject(arg1), getObject(arg2));
                return addHeapObject(ret);
            },
            __wbg_set_create_1bebf2add702f8d5: function(arg0, arg1) {
                getObject(arg0).create = arg1 !== 0;
            },
            __wbg_set_create_ef897736206a6f05: function(arg0, arg1) {
                getObject(arg0).create = arg1 !== 0;
            },
            __wbg_set_key_path_3c45a8ff0b89e678: function(arg0, arg1) {
                getObject(arg0).keyPath = getObject(arg1);
            },
            __wbg_set_onabort_63885d8d7841a8d5: function(arg0, arg1) {
                getObject(arg0).onabort = getObject(arg1);
            },
            __wbg_set_oncomplete_f31e6dc6d16c1ff8: function(arg0, arg1) {
                getObject(arg0).oncomplete = getObject(arg1);
            },
            __wbg_set_onerror_8a268cb237177bba: function(arg0, arg1) {
                getObject(arg0).onerror = getObject(arg1);
            },
            __wbg_set_onerror_c1ecd6233c533c08: function(arg0, arg1) {
                getObject(arg0).onerror = getObject(arg1);
            },
            __wbg_set_onsuccess_fca94ded107b64af: function(arg0, arg1) {
                getObject(arg0).onsuccess = getObject(arg1);
            },
            __wbg_set_onupgradeneeded_860ce42184f987e7: function(arg0, arg1) {
                getObject(arg0).onupgradeneeded = getObject(arg1);
            },
            __wbg_size_5c83ce43b4341b3d: function(arg0) {
                const ret = getObject(arg0).size;
                return ret;
            },
            __wbg_slice_66f9d6a0aa4717dd: function(arg0, arg1, arg2) {
                const ret = getObject(arg0).slice(arg1 >>> 0, arg2 >>> 0);
                return addHeapObject(ret);
            },
            __wbg_static_accessor_GLOBAL_8adb955bd33fac2f: function() {
                const ret = typeof global === 'undefined' ? null : global;
                return isLikeNone(ret) ? 0 : addHeapObject(ret);
            },
            __wbg_static_accessor_GLOBAL_THIS_ad356e0db91c7913: function() {
                const ret = typeof globalThis === 'undefined' ? null : globalThis;
                return isLikeNone(ret) ? 0 : addHeapObject(ret);
            },
            __wbg_static_accessor_SELF_f207c857566db248: function() {
                const ret = typeof self === 'undefined' ? null : self;
                return isLikeNone(ret) ? 0 : addHeapObject(ret);
            },
            __wbg_static_accessor_WINDOW_bb9f1ba69d61b386: function() {
                const ret = typeof window === 'undefined' ? null : window;
                return isLikeNone(ret) ? 0 : addHeapObject(ret);
            },
            __wbg_storage_8d917976d6753ee0: function(arg0) {
                const ret = getObject(arg0).storage;
                return addHeapObject(ret);
            },
            __wbg_subarray_a068d24e39478a8a: function(arg0, arg1, arg2) {
                const ret = getObject(arg0).subarray(arg1 >>> 0, arg2 >>> 0);
                return addHeapObject(ret);
            },
            __wbg_target_7bc90f314634b37b: function(arg0) {
                const ret = getObject(arg0).target;
                return isLikeNone(ret) ? 0 : addHeapObject(ret);
            },
            __wbg_then_098abe61755d12f6: function(arg0, arg1) {
                const ret = getObject(arg0).then(getObject(arg1));
                return addHeapObject(ret);
            },
            __wbg_then_9e335f6dd892bc11: function(arg0, arg1, arg2) {
                const ret = getObject(arg0).then(getObject(arg1), getObject(arg2));
                return addHeapObject(ret);
            },
            __wbg_toString_3272fa0dfd05dd87: function(arg0) {
                const ret = getObject(arg0).toString();
                return addHeapObject(ret);
            },
            __wbg_toString_3519669280f5580f: function() { return handleError(function (arg0, arg1) {
                const ret = getObject(arg0).toString(arg1);
                return addHeapObject(ret);
            }, arguments); },
            __wbg_transaction_1309b463c399d2b3: function() { return handleError(function (arg0, arg1, arg2, arg3) {
                const ret = getObject(arg0).transaction(getStringFromWasm0(arg1, arg2), __wbindgen_enum_IdbTransactionMode[arg3]);
                return addHeapObject(ret);
            }, arguments); },
            __wbg_transaction_5eb9f1f16e8c769b: function(arg0) {
                const ret = getObject(arg0).transaction;
                return addHeapObject(ret);
            },
            __wbg_truncate_af8ac1613ab66393: function() { return handleError(function (arg0, arg1) {
                getObject(arg0).truncate(arg1);
            }, arguments); },
            __wbg_truncate_c40d347b5bd45c12: function() { return handleError(function (arg0, arg1) {
                getObject(arg0).truncate(arg1 >>> 0);
            }, arguments); },
            __wbg_upperBound_482c10cb5e387300: function() { return handleError(function (arg0, arg1) {
                const ret = IDBKeyRange.upperBound(getObject(arg0), arg1 !== 0);
                return addHeapObject(ret);
            }, arguments); },
            __wbg_value_21fc78aab0322612: function(arg0) {
                const ret = getObject(arg0).value;
                return addHeapObject(ret);
            },
            __wbg_write_3bcdc311a9e138ff: function() { return handleError(function (arg0, arg1, arg2) {
                const ret = getObject(arg0).write(getObject(arg1), getObject(arg2));
                return ret;
            }, arguments); },
            __wbg_write_57c477a82b886339: function() { return handleError(function (arg0, arg1, arg2, arg3) {
                const ret = getObject(arg0).write(getArrayU8FromWasm0(arg1, arg2), getObject(arg3));
                return ret;
            }, arguments); },
            __wbindgen_cast_0000000000000001: function(arg0, arg1) {
                // Cast intrinsic for `Closure(Closure { dtor_idx: 28, function: Function { arguments: [Externref], shim_idx: 60, ret: Result(Unit), inner_ret: Some(Result(Unit)) }, mutable: true }) -> Externref`.
                const ret = makeMutClosure(arg0, arg1, wasm.__wasm_bindgen_func_elem_588, __wasm_bindgen_func_elem_1205);
                return addHeapObject(ret);
            },
            __wbindgen_cast_0000000000000002: function(arg0, arg1) {
                // Cast intrinsic for `Closure(Closure { dtor_idx: 28, function: Function { arguments: [NamedExternref("Event")], shim_idx: 29, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
                const ret = makeMutClosure(arg0, arg1, wasm.__wasm_bindgen_func_elem_588, __wasm_bindgen_func_elem_589);
                return addHeapObject(ret);
            },
            __wbindgen_cast_0000000000000003: function(arg0, arg1) {
                // Cast intrinsic for `Closure(Closure { dtor_idx: 28, function: Function { arguments: [NamedExternref("IDBVersionChangeEvent")], shim_idx: 60, ret: Result(Unit), inner_ret: Some(Result(Unit)) }, mutable: true }) -> Externref`.
                const ret = makeMutClosure(arg0, arg1, wasm.__wasm_bindgen_func_elem_588, __wasm_bindgen_func_elem_1205_2);
                return addHeapObject(ret);
            },
            __wbindgen_cast_0000000000000004: function(arg0, arg1) {
                // Cast intrinsic for `Closure(Closure { dtor_idx: 28, function: Function { arguments: [], shim_idx: 31, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
                const ret = makeMutClosure(arg0, arg1, wasm.__wasm_bindgen_func_elem_588, __wasm_bindgen_func_elem_592);
                return addHeapObject(ret);
            },
            __wbindgen_cast_0000000000000005: function(arg0) {
                // Cast intrinsic for `F64 -> Externref`.
                const ret = arg0;
                return addHeapObject(ret);
            },
            __wbindgen_cast_0000000000000006: function(arg0, arg1) {
                // Cast intrinsic for `Ref(String) -> Externref`.
                const ret = getStringFromWasm0(arg0, arg1);
                return addHeapObject(ret);
            },
            __wbindgen_object_clone_ref: function(arg0) {
                const ret = getObject(arg0);
                return addHeapObject(ret);
            },
            __wbindgen_object_drop_ref: function(arg0) {
                takeObject(arg0);
            },
        };
        return {
            __proto__: null,
            "./isar_bg.js": import0,
        };
    }

    function __wasm_bindgen_func_elem_592(arg0, arg1) {
        wasm.__wasm_bindgen_func_elem_592(arg0, arg1);
    }

    function __wasm_bindgen_func_elem_589(arg0, arg1, arg2) {
        wasm.__wasm_bindgen_func_elem_589(arg0, arg1, addHeapObject(arg2));
    }

    function __wasm_bindgen_func_elem_1205(arg0, arg1, arg2) {
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.__wasm_bindgen_func_elem_1205(retptr, arg0, arg1, addHeapObject(arg2));
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            if (r1) {
                throw takeObject(r0);
            }
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
        }
    }

    function __wasm_bindgen_func_elem_1205_2(arg0, arg1, arg2) {
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.__wasm_bindgen_func_elem_1205_2(retptr, arg0, arg1, addHeapObject(arg2));
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            if (r1) {
                throw takeObject(r0);
            }
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
        }
    }


    const __wbindgen_enum_IdbRequestReadyState = ["pending", "done"];


    const __wbindgen_enum_IdbTransactionMode = ["readonly", "readwrite", "versionchange", "readwriteflush", "cleanup"];

    function addHeapObject(obj) {
        if (heap_next === heap.length) heap.push(heap.length + 1);
        const idx = heap_next;
        heap_next = heap[idx];

        heap[idx] = obj;
        return idx;
    }

    const CLOSURE_DTORS = (typeof FinalizationRegistry === 'undefined')
        ? { register: () => {}, unregister: () => {} }
        : new FinalizationRegistry(state => state.dtor(state.a, state.b));

    function debugString(val) {
        // primitive types
        const type = typeof val;
        if (type == 'number' || type == 'boolean' || val == null) {
            return  `${val}`;
        }
        if (type == 'string') {
            return `"${val}"`;
        }
        if (type == 'symbol') {
            const description = val.description;
            if (description == null) {
                return 'Symbol';
            } else {
                return `Symbol(${description})`;
            }
        }
        if (type == 'function') {
            const name = val.name;
            if (typeof name == 'string' && name.length > 0) {
                return `Function(${name})`;
            } else {
                return 'Function';
            }
        }
        // objects
        if (Array.isArray(val)) {
            const length = val.length;
            let debug = '[';
            if (length > 0) {
                debug += debugString(val[0]);
            }
            for(let i = 1; i < length; i++) {
                debug += ', ' + debugString(val[i]);
            }
            debug += ']';
            return debug;
        }
        // Test for built-in
        const builtInMatches = /\[object ([^\]]+)\]/.exec(toString.call(val));
        let className;
        if (builtInMatches && builtInMatches.length > 1) {
            className = builtInMatches[1];
        } else {
            // Failed to match the standard '[object ClassName]'
            return toString.call(val);
        }
        if (className == 'Object') {
            // we're a user defined class or Object
            // JSON.stringify avoids problems with cycles, and is generally much
            // easier than looping through ownProperties of `val`.
            try {
                return 'Object(' + JSON.stringify(val) + ')';
            } catch (_) {
                return 'Object';
            }
        }
        // errors
        if (val instanceof Error) {
            return `${val.name}: ${val.message}\n${val.stack}`;
        }
        // TODO we could test for more things here, like `Set`s and `Map`s.
        return className;
    }

    function dropObject(idx) {
        if (idx < 1028) return;
        heap[idx] = heap_next;
        heap_next = idx;
    }

    function getArrayU8FromWasm0(ptr, len) {
        ptr = ptr >>> 0;
        return getUint8ArrayMemory0().subarray(ptr / 1, ptr / 1 + len);
    }

    let cachedDataViewMemory0 = null;
    function getDataViewMemory0() {
        if (cachedDataViewMemory0 === null || cachedDataViewMemory0.buffer.detached === true || (cachedDataViewMemory0.buffer.detached === undefined && cachedDataViewMemory0.buffer !== wasm.memory.buffer)) {
            cachedDataViewMemory0 = new DataView(wasm.memory.buffer);
        }
        return cachedDataViewMemory0;
    }

    function getStringFromWasm0(ptr, len) {
        ptr = ptr >>> 0;
        return decodeText(ptr, len);
    }

    let cachedUint8ArrayMemory0 = null;
    function getUint8ArrayMemory0() {
        if (cachedUint8ArrayMemory0 === null || cachedUint8ArrayMemory0.byteLength === 0) {
            cachedUint8ArrayMemory0 = new Uint8Array(wasm.memory.buffer);
        }
        return cachedUint8ArrayMemory0;
    }

    function getObject(idx) { return heap[idx]; }

    function handleError(f, args) {
        try {
            return f.apply(this, args);
        } catch (e) {
            wasm.__wbindgen_export3(addHeapObject(e));
        }
    }

    let heap = new Array(1024).fill(undefined);
    heap.push(undefined, null, true, false);

    let heap_next = heap.length;

    function isLikeNone(x) {
        return x === undefined || x === null;
    }

    function makeMutClosure(arg0, arg1, dtor, f) {
        const state = { a: arg0, b: arg1, cnt: 1, dtor };
        const real = (...args) => {

            // First up with a closure we increment the internal reference
            // count. This ensures that the Rust closure environment won't
            // be deallocated while we're invoking it.
            state.cnt++;
            const a = state.a;
            state.a = 0;
            try {
                return f(a, state.b, ...args);
            } finally {
                state.a = a;
                real._wbg_cb_unref();
            }
        };
        real._wbg_cb_unref = () => {
            if (--state.cnt === 0) {
                state.dtor(state.a, state.b);
                state.a = 0;
                CLOSURE_DTORS.unregister(state);
            }
        };
        CLOSURE_DTORS.register(real, state, state);
        return real;
    }

    function passStringToWasm0(arg, malloc, realloc) {
        if (realloc === undefined) {
            const buf = cachedTextEncoder.encode(arg);
            const ptr = malloc(buf.length, 1) >>> 0;
            getUint8ArrayMemory0().subarray(ptr, ptr + buf.length).set(buf);
            WASM_VECTOR_LEN = buf.length;
            return ptr;
        }

        let len = arg.length;
        let ptr = malloc(len, 1) >>> 0;

        const mem = getUint8ArrayMemory0();

        let offset = 0;

        for (; offset < len; offset++) {
            const code = arg.charCodeAt(offset);
            if (code > 0x7F) break;
            mem[ptr + offset] = code;
        }
        if (offset !== len) {
            if (offset !== 0) {
                arg = arg.slice(offset);
            }
            ptr = realloc(ptr, len, len = offset + arg.length * 3, 1) >>> 0;
            const view = getUint8ArrayMemory0().subarray(ptr + offset, ptr + len);
            const ret = cachedTextEncoder.encodeInto(arg, view);

            offset += ret.written;
            ptr = realloc(ptr, len, offset, 1) >>> 0;
        }

        WASM_VECTOR_LEN = offset;
        return ptr;
    }

    function takeObject(idx) {
        const ret = getObject(idx);
        dropObject(idx);
        return ret;
    }

    let cachedTextDecoder = new TextDecoder('utf-8', { ignoreBOM: true, fatal: true });
    cachedTextDecoder.decode();
    function decodeText(ptr, len) {
        return cachedTextDecoder.decode(getUint8ArrayMemory0().subarray(ptr, ptr + len));
    }

    const cachedTextEncoder = new TextEncoder();

    if (!('encodeInto' in cachedTextEncoder)) {
        cachedTextEncoder.encodeInto = function (arg, view) {
            const buf = cachedTextEncoder.encode(arg);
            view.set(buf);
            return {
                read: arg.length,
                written: buf.length
            };
        };
    }

    let WASM_VECTOR_LEN = 0;

    let wasmModule, wasm;
    function __wbg_finalize_init(instance, module) {
        wasm = instance.exports;
        wasmModule = module;
        cachedDataViewMemory0 = null;
        cachedUint8ArrayMemory0 = null;
        return wasm;
    }

    async function __wbg_load(module, imports) {
        if (typeof Response === 'function' && module instanceof Response) {
            if (typeof WebAssembly.instantiateStreaming === 'function') {
                try {
                    return await WebAssembly.instantiateStreaming(module, imports);
                } catch (e) {
                    const validResponse = module.ok && expectedResponseType(module.type);

                    if (validResponse && module.headers.get('Content-Type') !== 'application/wasm') {
                        console.warn("`WebAssembly.instantiateStreaming` failed because your server does not serve Wasm with `application/wasm` MIME type. Falling back to `WebAssembly.instantiate` which is slower. Original error:\n", e);

                    } else { throw e; }
                }
            }

            const bytes = await module.arrayBuffer();
            return await WebAssembly.instantiate(bytes, imports);
        } else {
            const instance = await WebAssembly.instantiate(module, imports);

            if (instance instanceof WebAssembly.Instance) {
                return { instance, module };
            } else {
                return instance;
            }
        }

        function expectedResponseType(type) {
            switch (type) {
                case 'basic': case 'cors': case 'default': return true;
            }
            return false;
        }
    }

    function initSync(module) {
        if (wasm !== undefined) return wasm;


        if (module !== undefined) {
            if (Object.getPrototypeOf(module) === Object.prototype) {
                ({module} = module)
            } else {
                console.warn('using deprecated parameters for `initSync()`; pass a single object instead')
            }
        }

        const imports = __wbg_get_imports();
        if (!(module instanceof WebAssembly.Module)) {
            module = new WebAssembly.Module(module);
        }
        const instance = new WebAssembly.Instance(module, imports);
        return __wbg_finalize_init(instance, module);
    }

    async function __wbg_init(module_or_path) {
        if (wasm !== undefined) return wasm;


        if (module_or_path !== undefined) {
            if (Object.getPrototypeOf(module_or_path) === Object.prototype) {
                ({module_or_path} = module_or_path)
            } else {
                console.warn('using deprecated parameters for the initialization function; pass a single object instead')
            }
        }

        if (module_or_path === undefined && script_src !== undefined) {
            module_or_path = script_src.replace(/\.js$/, "_bg.wasm");
        }
        const imports = __wbg_get_imports();

        if (typeof module_or_path === 'string' || (typeof Request === 'function' && module_or_path instanceof Request) || (typeof URL === 'function' && module_or_path instanceof URL)) {
            module_or_path = fetch(module_or_path);
        }

        const { instance, module } = await __wbg_load(await module_or_path, imports);

        return __wbg_finalize_init(instance, module);
    }

    return Object.assign(__wbg_init, { initSync }, exports);
})({ __proto__: null });
