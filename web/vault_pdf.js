// Printing's default remote PDF.js is replaced by a pinned, same-origin build.
// Publish the adapter synchronously so the plugin never falls back to its CDN.
(() => {
  'use strict';
  const base = new URL('vendor/pdfjs/', document.currentScript.src);
  const worker = new URL('pdf.worker.mjs', base).href;
  let library;
  const load = () => library ??= import(new URL('pdf.mjs', base).href).then(pdf => {
    pdf.GlobalWorkerOptions.workerSrc = worker;
    return pdf;
  });
  globalThis.pdfjsLib = Object.freeze({
    GlobalWorkerOptions: Object.freeze({workerSrc: worker}),
    getDocument(settings) {
      if (!(settings.data instanceof Uint8Array)) throw new Error('Local PDF bytes required');
      const task = load().then(pdf => pdf.getDocument({
        data: settings.data,
        isEvalSupported: false,
        enableXfa: false,
        cMapUrl: new URL('cmaps/', base).href,
        cMapPacked: true,
        standardFontDataUrl: new URL('standard_fonts/', base).href,
        wasmUrl: new URL('wasm/', base).href,
      }));
      return {
        promise: task.then(value => value.promise),
        destroy: () => task.then(value => value.destroy()),
      };
    },
  });
})();
