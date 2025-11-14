// deno-lint-ignore-file no-explicit-any
/**
 * react_tools.ts — Interactive React component/layout scaffolder for Deno.
 * Author Thomi Jasir<thomijasir@gmail.com>
 * Prompt order:
 *  1) Name of component (must provide, suffix by dot)
 *  2) Target dir (blank → ".")
 *  3) Controller (y / n / <custom basename> -> "<custom>.ts")
 *  4) Test file (y / n / <custom basename> -> "<custom>.ts", default y)
 *  5) Interface (y/n, default y)
 *
 * Rules:
 *  • Always create index.ts
 *  • Always create folder "<dir>/<Name>"
 *  • Suffix by dot: "Name.suffix" => suffix = "suffix", else "component"
 */

//
// ========== Colors & Icons ==========
//
const C = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
  cyan: "\x1b[36m",
  gray: "\x1b[90m",
};
const b = (s: string) => `${C.bold}${s}${C.reset}`;
const dim = (s: string) => `${C.dim}${s}${C.reset}`;
const green = (s: string) => `${C.green}${s}${C.reset}`;
const yellow = (s: string) => `${C.yellow}${s}${C.reset}`;
const red = (s: string) => `${C.red}${s}${C.reset}`;
const cyan = (s: string) => `${C.cyan}${s}${C.reset}`;
const gray = (s: string) => `${C.gray}${s}${C.reset}`;

//
// ========== Types ==========
//
type Plan = {
  nameRaw: string;
  namePascal: string;
  suffix: string;
  baseDir: string;
  withInterface: boolean;
  test: { create: boolean; filename?: string; isCustom: boolean };
  controller: { create: boolean; filename?: string; isCustom: boolean };
  paths: {
    component: string;
    iface?: string;
    test?: string;
    controller?: string;
    index: string;
  };
};

//
// ========== Docs Banner ==========
//
function banner(): void {
  console.log(`
${b("────────────────────────────────────────────────────────────────────")}
${b("  🧩 React Tools (Interactive · Deno)")}
${b("────────────────────────────────────────────────────────────────────")}

${cyan("🔤 Naming & suffix")}
  • No dot → default suffix = ${b("component")}
      e.g., ${b("ButtonCard")} → ${dim("ButtonCard.component.tsx")}
  • With dot → suffix = part after last dot
      e.g., ${b("Dashboard.layout")} → ${dim("Dashboard.layout.tsx")}

${cyan("📦 Files generated")}
  • <Name>.<suffix>.tsx       ${gray("(React component/layout)")}
  • <Name>.interface.ts       ${gray("(Props interface)")} ${yellow("[optional]")}
  • <Name>.<suffix>.test.ts   ${gray("(simple render test; no snapshot)")} ${yellow("[optional]")}
  • <Name>.controller.ts      ${gray("(controller module / hook)")} ${yellow("[optional]")}
  • index.ts                  ${gray("(default export + Props type when available; controller re-export)")} ${green("[always]")}

${cyan("⚙️ Defaults & behavior")}
  • Target directory prompt (blank → ${b(".")})
  • Always create dedicated folder: ${dim("<dir>/<Name>")}
  • ${b("Interface")}: default ${green("Yes")}
  • ${b("Test")}: default ${green("Yes")}
  • ${b("Controller")}: default ${yellow("No")} ${gray("(you can enter a custom basename)")}
  • Overwrite on conflicts: ${green("y")}es / ${red("n")}o / ${b("a")}ll / ${b("s")}kip all

${cyan("🧪 Test prompt options")}
  • ${green("y")} → create default: ${dim("<Name>.<suffix>.test.ts")}
  • ${red("n")} → skip
  • ${b("<custom>")} → create ${dim("<custom>.ts")}
      e.g., input ${b("UserCard.test")} → file ${dim("UserCard.test.ts")}

${cyan("🎮 Controller prompt options")}
  • ${green("y")} → create default: ${dim("<Name>.controller.ts")}
  • ${red("n")} → skip
  • ${b("<custom>")} → create ${dim("<custom>.ts")}
      e.g., input ${b("DashboardCtrl")} → file ${dim("DashboardCtrl.ts")}

${b("────────────────────────────────────────────────────────────────────")}
`);
}

//
// ========== Prompt helpers (multiline style) ==========
//
function promptMultiline(
  message: string,
  requireValue: boolean,
  defaultValue = "",
): string {
  console.log(message);
  while (true) {
    const v = prompt("> ", defaultValue);
    const trimmed = v?.trim() ?? "";
    if (requireValue) {
      if (trimmed.length > 0) return trimmed;
      if (defaultValue.trim().length > 0) return defaultValue.trim();
      console.log(red("Please provide a value."));
    } else {
      return trimmed; // blank allowed
    }
  }
}

function promptYesNo(message: string, defaultYes = true): boolean {
  const suffix = defaultYes ? "Y/n" : "y/N";
  const v = prompt(`${message} (${suffix})`, defaultYes ? "y" : "n")
    ?.trim()
    .toLowerCase();
  if (!v) return defaultYes;
  return ["y", "yes"].includes(v);
}

//
// ========== Name & paths ==========
//
function toPascalCase(input: string): string {
  return input
    .replace(/[-_.]+/g, " ")
    .split(" ")
    .filter(Boolean)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join("");
}

function parseNameAndSuffix(input: string): { base: string; suffix: string } {
  const lastDot = input.lastIndexOf(".");
  if (lastDot === -1) return { base: input, suffix: "component" };
  const base = input.slice(0, lastDot);
  const suffix = input.slice(lastDot + 1).trim();
  return { base: base || input, suffix: suffix || "component" };
}

function joinPath(...parts: string[]): string {
  const raw = parts.join("/");
  return raw.replace(/\/+/g, "/").replace(/\/$/, "");
}

function sanitizeBaseFileName(input: string): string {
  // limit to basename (no directories), remove leading dots
  return input.replace(/[\\\/]/g, "").replace(/^\.+/, "");
}

async function pathExists(path: string): Promise<boolean> {
  try {
    await Deno.stat(path);
    return true;
  } catch {
    return false;
  }
}

async function ensureDir(path: string): Promise<void> {
  await Deno.mkdir(path, { recursive: true });
}

//
// ========== Templates ==========
//
function componentTemplate(
  namePascal: string,
  withInterface: boolean,
  withController: boolean,
): string {
  // Imports
  let imports = `import React from "react";\n`;
  if (withController) {
    imports += `import { use${namePascal}Controller as useController } from "./${namePascal}.controller";\n`;
  }
  if (withInterface) {
    imports += `import type { ${namePascal}Props } from "./${namePascal}.interface";\n`;
  }

  // Signature
  const signature = withInterface ? `React.FC<${namePascal}Props>` : "React.FC";

  // Body (controller state/actions only when controller exists)
  const controllerSetup = withController
    ? `  const { actions, state } = useController();
  console.log({ actions, state })\n`
    : "";
  const helloLine = withController
    ? `<p>Hello, {state.name}</p>`
    : `<p>Hello, ${namePascal}</p>`;

  return `${imports}
export const ${namePascal}: ${signature} = (_props) => {
${controllerSetup}  return (
    <div>
      ${helloLine}
    </div>
  );
};
`;
}

function interfaceTemplate(namePascal: string): string {
  return `export interface ${namePascal}Props {}
`;
}

function testTemplate(namePascal: string, suffix: string): string {
  return `import React from "react";
import { render, screen } from "@testing-library/react";
import { ${namePascal} } from "./${namePascal}.${suffix}";

describe("${namePascal}", () => {
  it("renders default content", () => {
    render(React.createElement(${namePascal}));
  });
});
`;
}

function controllerTemplate(namePascal: string): string {
  return `/* -----------------------------------------------------------------------------
 * Domain Business Logic for ${namePascal}
 * -----------------------------------------------------------------------------
 * Keep these functions pure and easily testable. They can be imported in tests
 * or used internally and only belongs to single use/view cannot shared.
 */

export const use${namePascal}Controller = () => {
  return {
    actions: {},
    state: {
      name: "its from controller ${namePascal}",
    },
  };
};
`;
}

function indexTemplate(
  namePascal: string,
  suffix: string,
  withInterface: boolean,
): string {
  const lines: string[] = [];
  // Re-export default & named component
  lines.push(
    `export { ${namePascal} as default, ${namePascal} } from "./${namePascal}.${suffix}";`,
  );
  if (withInterface) {
    lines.push(
      `export type { ${namePascal}Props } from "./${namePascal}.interface";`,
    );
  }
  return lines.join("\n") + "\n";
}

//
// ========== Planning ==========
//
function makePlan(
  nameInput: string,
  dirInput: string,
  withInterface: boolean,
  testAnswer: string,
  controllerAnswer: string,
): Plan {
  const { base, suffix } = parseNameAndSuffix(nameInput.trim());
  const namePascal = toPascalCase(base);
  const dir = dirInput.trim() === "" ? "." : dirInput.trim();

  // Always create "<dir>/<Name>"
  const baseDir = joinPath(dir, namePascal);

  // Test behavior
  let testCreate = true;
  let testIsCustom = false;
  let testFileName: string | undefined;
  const defaultTestBase = `${namePascal}.${suffix}.test.ts`;
  const tAns = (testAnswer || "y").trim().toLowerCase();

  if (tAns === "y" || tAns === "yes" || tAns === "") {
    testCreate = true;
    testIsCustom = false;
    testFileName = defaultTestBase;
  } else if (tAns === "n" || tAns === "no") {
    testCreate = false;
    testIsCustom = false;
    testFileName = undefined;
  } else {
    testCreate = true;
    testIsCustom = true;
    const baseOnly = sanitizeBaseFileName(testAnswer.trim());
    testFileName = baseOnly.endsWith(".ts") ? baseOnly : `${baseOnly}.ts`;
  }

  // Controller behavior (default: no)
  let ctrlCreate = false;
  let ctrlIsCustom = false;
  let ctrlFileName: string | undefined;
  const defaultCtrlBase = `${namePascal}.controller.ts`;
  const cAns = (controllerAnswer || "n").trim().toLowerCase();

  if (cAns === "y" || cAns === "yes") {
    ctrlCreate = true;
    ctrlIsCustom = false;
    ctrlFileName = defaultCtrlBase;
  } else if (cAns === "n" || cAns === "no" || cAns === "") {
    ctrlCreate = false;
    ctrlIsCustom = false;
    ctrlFileName = undefined;
  } else {
    ctrlCreate = true;
    ctrlIsCustom = true;
    const baseOnly = sanitizeBaseFileName(controllerAnswer.trim());
    ctrlFileName = baseOnly.endsWith(".ts") ? baseOnly : `${baseOnly}.ts`;
  }

  const componentPath = joinPath(baseDir, `${namePascal}.${suffix}.tsx`);
  const ifacePath = withInterface
    ? joinPath(baseDir, `${namePascal}.interface.ts`)
    : undefined;
  const testPath =
    testCreate && testFileName ? joinPath(baseDir, testFileName) : undefined;
  const controllerPath =
    ctrlCreate && ctrlFileName ? joinPath(baseDir, ctrlFileName) : undefined;
  const indexPath = joinPath(baseDir, `index.ts`);

  return {
    nameRaw: nameInput.trim(),
    namePascal,
    suffix,
    baseDir,
    withInterface,
    test: {
      create: testCreate,
      filename: testFileName,
      isCustom: testIsCustom,
    },
    controller: {
      create: ctrlCreate,
      filename: ctrlFileName,
      isCustom: ctrlIsCustom,
    },
    paths: {
      component: componentPath,
      iface: ifacePath,
      test: testPath,
      controller: controllerPath,
      index: indexPath,
    },
  };
}

function showPlan(plan: Plan): void {
  console.log(`\n${b("🧭 Planned generation")}`);
  console.log(`  ${cyan("Name")}:            ${b(plan.namePascal)}`);
  console.log(`  ${cyan("Suffix")}:          ${b(plan.suffix)}`);
  console.log(
    `  ${cyan("Directory")}:       ${b(plan.baseDir)}  ${gray('(always creates "<Name>" folder)')}`,
  );
  console.log(
    `  ${cyan("Interface")}:        ${plan.withInterface ? green("Yes") : yellow("No")}`,
  );
  console.log(
    `  ${cyan("Test")}:             ${plan.test.create ? green(plan.test.filename || "") : yellow("No")}`,
  );
  console.log(
    `  ${cyan("Controller")}:       ${plan.controller.create ? green(plan.controller.filename || "") : yellow("No")}`,
  );
  console.log(`  ${cyan("Files")}:`);
  console.log(`    • ${plan.paths.component}`);
  if (plan.paths.iface) console.log(`    • ${plan.paths.iface}`);
  if (plan.paths.test) console.log(`    • ${plan.paths.test}`);
  if (plan.paths.controller) console.log(`    • ${plan.paths.controller}`);
  console.log(`    • ${plan.paths.index} ${green("(always)")}`);
}

//
// ========== Writing with conflict handling ==========
//
async function writeFileSmart(
  filePath: string,
  content: string,
  overwriteAllState: { overwriteAll: boolean; skipAll: boolean },
): Promise<void> {
  const exists = await pathExists(filePath);
  let shouldWrite = true;

  if (exists && !overwriteAllState.overwriteAll && !overwriteAllState.skipAll) {
    const choice = prompt(
      `⚠️  File exists: ${filePath}\nOverwrite this file? (y=Yes / n=No / a=All / s=Skip all)`,
      "n",
    )
      ?.trim()
      .toLowerCase();

    if (choice === "a" || choice === "all") {
      overwriteAllState.overwriteAll = true;
      shouldWrite = true;
    } else if (choice === "s" || choice === "skip") {
      overwriteAllState.skipAll = true;
      shouldWrite = false;
    } else if (choice === "y" || choice === "yes") {
      shouldWrite = true;
    } else {
      shouldWrite = false;
    }
  } else if (exists && overwriteAllState.skipAll) {
    shouldWrite = false;
  } else if (exists && overwriteAllState.overwriteAll) {
    shouldWrite = true;
  }

  if (!exists || shouldWrite) {
    await Deno.writeTextFile(filePath, content);
    console.log(`  ${green("✅ Wrote")} ${filePath}`);
  } else {
    console.log(`  ${yellow("⏭️  Skipped")} ${filePath}`);
  }
}

//
// ========== Main interactive flow ==========
//
async function runInteractive(): Promise<void> {
  banner();

  // 1) Name (must provide; dot sets suffix)
  const nameInput = promptMultiline(
    `${b("📝 Name of component")} — use dot for suffix (e.g., ${b("ButtonCard")} or ${b("Dashboard.layout")})`,
    true,
    "",
  );

  // 2) Target dir (blank → ".")
  const dirInput = promptMultiline(
    `${b("📂 Target directory")} (blank defaults to ".")`,
    false,
    ".",
  );

  // 3) Controller (y/n/custom)
  const ctrlHelp = `${green("y")}=default ${dim("<Name>.controller.ts")}  ${red("n")}=skip  ${b("<custom>")}=basename → ${dim("<custom>.ts")}`;
  const controllerAnswer = promptMultiline(
    `${b("🎮 Controller file?")} ${gray(`(${ctrlHelp})`)}`,
    false,
    "n",
  );

  // 4) Test file (y/n/custom; default y)
  const testHelp = `${green("y")}=default ${dim("<Name>.<suffix>.test.ts")}  ${red("n")}=skip  ${b("<custom>")}=basename → ${dim("<custom>.ts")}`;
  const testAnswer = promptMultiline(
    `${b("🧪 Test file?")} ${gray(`(${testHelp})`)}`,
    false,
    "y",
  );

  // 5) Interface (default yes)
  const withInterface = promptYesNo(
    `${b("🔧 Create interface file")} & use <Name>Props?`,
    true,
  );

  // Plan + preview
  const plan = makePlan(
    nameInput,
    dirInput,
    withInterface,
    testAnswer,
    controllerAnswer,
  );
  showPlan(plan);

  // Confirm
  const proceed = promptYesNo(`${b("🚀 Proceed with generation?")}`, true);
  if (!proceed) {
    console.log(yellow("Aborted."));
    return;
  }

  // Ensure dir
  await ensureDir(plan.baseDir);

  // Write files
  console.log(`\n${b("✍️  Writing files...")}`);
  const state = { overwriteAll: false, skipAll: false };

  await writeFileSmart(
    plan.paths.component,
    componentTemplate(
      plan.namePascal,
      plan.withInterface,
      plan.controller.create,
    ),
    state,
  );
  if (plan.paths.iface) {
    await writeFileSmart(
      plan.paths.iface,
      interfaceTemplate(plan.namePascal),
      state,
    );
  }
  if (plan.paths.test) {
    await writeFileSmart(
      plan.paths.test,
      testTemplate(plan.namePascal, plan.suffix),
      state,
    );
  }
  if (plan.paths.controller) {
    await writeFileSmart(
      plan.paths.controller,
      controllerTemplate(plan.namePascal),
      state,
    );
  }

  const ctrlBaseForIndex =
    plan.controller.create && plan.controller.filename
      ? plan.controller.filename.replace(/^.*\//, "")
      : undefined;

  await writeFileSmart(
    plan.paths.index,
    indexTemplate(plan.namePascal, plan.suffix, plan.withInterface),
    state,
  );

  console.log(`\n${b("✨ Done.")} ${gray(`Location: ${plan.baseDir}`)}`);
}

if (import.meta.main) {
  await runInteractive();
}
