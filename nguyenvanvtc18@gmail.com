// ==UserScript==
// @name         Auto Layma V3 - Bypass & 2FA
// @namespace    https://github.com/YourUsername/Auto-Layma-V3
// @version      3.0.0
// @description  Tự động lấy link Quest, bỏ qua nhập thủ công và xử lý xác minh 2 bước trên Layma.net
// @author       YourName
// @match        *://layma.net/*
// @match        *://*.layma.net/*
// @grant        none
// @downloadURL  https://raw.githubusercontent.com/YourUsername/Auto-Layma-V3/main/Auto-Layma-V3.user.js
// @updateURL    https://raw.githubusercontent.com/YourUsername/Auto-Layma-V3/main/Auto-Layma-V3.user.js
// ==/UserScript==

(function() {
    'use strict';

    // Cấu hình thời gian chờ (ms)
    const WAIT_TIME = 3000;

    // Hàm chờ element xuất hiện trong DOM
    function waitForElement(selector, timeout = 10000) {
        return new Promise((resolve, reject) => {
            const startTime = Date.now();
            const interval = setInterval(() => {
                const element = document.querySelector(selector);
                if (element) {
                    clearInterval(interval);
                    resolve(element);
                } else if (Date.now() - startTime > timeout) {
                    clearInterval(interval);
                    reject(new Error(`Không tìm thấy element: ${selector}`));
                }
            }, 500);
        });
    }

    // Hàm lấy link Quest tự động (Logic cần cập nhật theo DOM thực tế)
    function getAutoQuestLink() {
        // TODO: Thay thế bằng logic lấy link thực tế từ API hoặc DOM của Layma
        // Ví dụ: return document.querySelector('.quest-link-hidden')?.value || null;
        
        console.log("[Layma Script] Đang cố gắng lấy link tự động...");
        return null; 
    }

    // Hàm xử lý xác minh 2 bước (2FA)
    async function handle2FAVerification() {
        console.log("[Layma Script] Bắt đầu xử lý xác minh 2 bước...");
        
        try {
            // 1. Chờ form xác minh xuất hiện
            await waitForElement('.verification-form', 15000); 

            // 2. Kiểm tra nếu có Captcha
            if (document.querySelector('iframe[src*="hcaptcha"]') || document.querySelector('.g-recaptcha')) {
                console.log("[Layma Script] Phát hiện Captcha. Cần giải thủ công hoặc tích hợp API.");
                return;
            }

            // 3. Kiểm tra nếu là nút xác minh qua link
            const verifyLinkBtn = document.querySelector('a.verify-link, button.verify-link');
            if (verifyLinkBtn) {
                console.log("[Layma Script] Tìm thấy nút xác minh link. Đang click...");
                verifyLinkBtn.click();
                return;
            }

            // 4. Kiểm tra nếu yêu cầu nhập mã OTP
            const otpInput = document.querySelector('input[name="otp"], input[placeholder*="mã"]');
            if (otpInput) {
                console.log("[Layma Script] Yêu cầu nhập OTP.");
            }

        } catch (error) {
            console.error("[Layma Script] Lỗi trong quá trình xác minh 2 bước:", error);
        }
    }

    // Hàm chính để bypass form nhập thủ công
    async function bypassManualInput() {
        console.log("[Layma Script] Bắt đầu quá trình Bypass...");

        // 1. Thử lấy link tự động
        const autoLink = getAutoQuestLink();

        if (autoLink) {
            console.log("[Layma Script] Đã lấy được link tự động:", autoLink);
            
            // Tìm ô input nhập link thủ công
            const manualInput = document.querySelector('input[placeholder="https://..."]');
            if (manualInput) {
                manualInput.value = autoLink;
                manualInput.dispatchEvent(new Event('input', { bubbles: true }));
                console.log("[Layma Script] Đã điền link vào ô input.");
            }

            // Tìm và click nút "Tiếp tục với link này"
            const continueBtn = Array.from(document.querySelectorAll('button')).find(
                btn => btn.textContent.includes('Tiếp tục với link này')
            );
            
            if (continueBtn) {
                console.log("[Layma Script] Đang click nút Tiếp tục...");
                continueBtn.click();
                
                // Chờ xử lý 2FA
                setTimeout(() => {
                    handle2FAVerification();
                }, WAIT_TIME);
            } else {
                console.log("[Layma Script] Không tìm thấy nút Tiếp tục.");
            }

        } else {
            console.log("[Layma Script] Không thể lấy link tự động. Script tạm dừng.");
        }
    }

    // Chạy script sau khi trang load xong
    window.addEventListener('load', () => {
        setTimeout(bypassManualInput, 2000);
    });

})();
