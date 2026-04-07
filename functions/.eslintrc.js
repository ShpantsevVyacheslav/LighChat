
module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
    "google",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json", "tsconfig.dev.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*", // Ignore built files.
    "/generated/**/*", // Ignore generated files.
  ],
  plugins: [
    "@typescript-eslint",
    "import",
  ],
  rules: {
    "quotes": "off",
    "no-trailing-spaces": "off",
    "import/no-unresolved": 0,
    "indent": "off",
    "max-len": "off",
    "object-curly-spacing": "off",
    "valid-jsdoc": "off",
    "require-jsdoc": "off",
    "camelcase": "off",
    "comma-dangle": "off",
    "arrow-parens": "off",
    "eol-last": "off",
    "no-multiple-empty-lines": "off"
  },
};
