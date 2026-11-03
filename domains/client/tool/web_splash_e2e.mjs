#!/usr/bin/env node
// E2E-проверка работоспособности web-версии (регрессия: приложение
// «зависало» на splash-экране и не переходило на логин).
//
// Скрипт открывает собранную web-сборку (build/web, раздаваемую локальным
// сервером) в headless Chrome и ждёт появления экрана логина ("Hi there").
// Если за WEB_E2E_TIMEOUT_MS (по умолчанию 120с) экран логина не появился —
// это регрессия splash-hang, скрипт завершается с ошибкой (exit 1).
//
// Использование:
//   node tool/web_splash_e2e.mjs [baseUrl]
//   WEB_E2E_URL=http://localhost:8000/ node tool/web_splash_e2e.mjs
//
// Требуется playwright-core и установленный Chrome/Chromium (на GitHub
// ubuntu-раннерах есть предустановленный Google Chrome — используется
// channel: 'chrome').

import { chromium } from 'playwright-core';

const url =
  process.argv[2] ||
  process.env.WEB_E2E_URL ||
  'http://localhost:8000/';
const timeoutMs = Number(process.env.WEB_E2E_TIMEOUT_MS || 120000);

function fail(message, extra) {
  console.error(`::error::${message}`);
  if (extra) console.error(extra);
  process.exit(1);
}

let browser;
// Путь к браузеру можно задать явно (окружения без системного Chrome).
const executablePath = process.env.WEB_E2E_BROWSER_PATH || undefined;
const launchOptions = {
  args: ['--no-sandbox', '--enable-unsafe-swiftshader'],
  ...(executablePath ? { executablePath } : {}),
};

try {
  // На GitHub ubuntu-раннерах есть предустановленный Google Chrome —
  // используем channel 'chrome'. Если его нет — пробуем системный/скачанный
  // браузер по WEB_E2E_BROWSER_PATH или playwright-chromium из кэша.
  browser = await chromium.launch({ ...launchOptions, channel: 'chrome' })
    .catch(() => chromium.launch(launchOptions));

  const page = await browser.newPage({ locale: 'en-US' });
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(String(error)));

  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });

  // В CanvasKit-рендере Flutter текст не попадает в DOM до включения
  // accessibility: активируем semantics-дерево кликом по
  // flt-semantics-placeholder, после чего текст виден как обычные узлы.
  const enableSemantics = async () => {
    try {
      await page.evaluate(() => {
        const placeholder = document.querySelector('flt-semantics-placeholder');
        if (placeholder) placeholder.click();
      });
    } catch {
      // До запуска Flutter-приложения placeholder'а ещё нет — попробуем позже.
    }
  };

  const waitForAppText = async (text, timeout) => {
    const deadline = Date.now() + timeout;
    let semanticsEnabled = false;
    while (Date.now() < deadline) {
      if (!semanticsEnabled) {
        await enableSemantics();
        semanticsEnabled = (await page.$('flt-semantics[role="button"]')) !== null;
      }
      const found = await page
        .getByText(text, { exact: false })
        .first()
        .isVisible()
        .catch(() => false);
      if (found) return true;
      await page.waitForTimeout(1000);
    }
    return false;
  };

  try {
    // Ключевой признак того, что splash завершился и отрисовался LoginPage.
    const ok = await waitForAppText('Hi there', timeoutMs);
    if (!ok) {
      fail(
        `Web app did not reach the login screen within ${timeoutMs} ms ` +
          `(splash hang regression?). URL: ${url}`
      );
    }
  } catch {
    fail(
      `Web app did not reach the login screen within ${timeoutMs} ms ` +
        `(splash hang regression?). URL: ${url}`
    );
  }

  // Экран логина должен содержать кнопки входа под пользователем.
  const hasLoginButtons = await waitForAppText('Login as', 30000);
  if (!hasLoginButtons) {
    fail(`Login screen is visible but 'Login as' section is missing. URL: ${url}`);
  }

  if (pageErrors.length > 0) {
    fail(`Uncaught page errors while loading the web app:`, pageErrors.join('\n'));
  }

  console.log(`E2E OK: web app reached the login screen at ${url}`);
} catch (error) {
  fail(`E2E web check failed: ${error}`);
} finally {
  if (browser) await browser.close();
}
