#!/usr/bin/env dotnet run
// ============================================================================
// Nome:        dotnet-update-sdk.cs
// Versão:      1.0.0
// Autor:       Jeann Andrade
// Descrição:   Atualiza o .NET SDK para a versão mais recente disponível via
//              apt (Ubuntu). Equivalente em C# file-based app (.NET 10) do
//              script dotnet-update-sdk.zsh.
//
// Observação:  File-based apps ainda não suportam múltiplos arquivos
//              (previsto para .NET 11), então os equivalentes de
//              shared-style.zsh e dotnet-common.zsh estão inlinados aqui
//              como funções locais, em vez de importados via #:include.
// ============================================================================

using System.Diagnostics;
using System.Text.RegularExpressions;

const string DotnetPkgPrefix = "dotnet-sdk";

Console.Clear();

// ----------------------------------------------------------------------
// Biblioteca de estilo (equivalente a shared-style.zsh)
// ----------------------------------------------------------------------

bool useColor = !Console.IsOutputRedirected;

string Colorize(string text, string ansiCode) =>
    useColor ? $"\u001b[{ansiCode}m{text}\u001b[0m" : text;

void SectionTitle(string title)
{
    Console.WriteLine();
    Console.WriteLine(Colorize($"── {title} ──", "1;36"));
}

void PrintField(string label, string value) =>
    Console.WriteLine($"  {Colorize(label + ":", "1")} {value}");

void PrintListItem(string item) =>
    Console.WriteLine($"    • {item}");

void Info(string msg) => Console.WriteLine(Colorize("[INFO] ", "36") + msg);
void Warn(string msg) => Console.WriteLine(Colorize("[AVISO]", "33") + " " + msg);
void Err(string msg) => Console.Error.WriteLine(Colorize("[ERRO] ", "31") + msg);
void Success(string msg) => Console.WriteLine(Colorize("[OK]   ", "32") + msg);

// ----------------------------------------------------------------------
// Biblioteca comum .NET (equivalente a dotnet-common.zsh)
// ----------------------------------------------------------------------

(int ExitCode, string StdOut, string StdErr) RunCommand(string file, string args, bool useSudo = false, bool streamOutput = false)
{
    var psi = new ProcessStartInfo
    {
        FileName = useSudo ? "sudo" : file,
        Arguments = useSudo ? $"{file} {args}" : args,
        RedirectStandardOutput = !streamOutput,
        RedirectStandardError = !streamOutput,
        UseShellExecute = false
    };

    using var process = Process.Start(psi)!;
    string stdout = streamOutput ? "" : process.StandardOutput.ReadToEnd();
    string stderr = streamOutput ? "" : process.StandardError.ReadToEnd();
    process.WaitForExit();
    return (process.ExitCode, stdout, stderr);
}

bool CommandExists(string command)
{
    var (exitCode, _, _) = RunCommand("which", command);
    return exitCode == 0;
}

void RequireCommand(string command, string message)
{
    if (!CommandExists(command))
    {
        Err(message);
        Environment.Exit(1);
    }
}

void CheckDotnet()
{
    if (!CommandExists("dotnet"))
    {
        Err("O comando 'dotnet' não foi encontrado após a instalação.");
        Environment.Exit(1);
    }
}

string GetSdkVersion()
{
    var (exitCode, stdout, _) = RunCommand("dotnet", "--version");
    return exitCode == 0 ? stdout.Trim() : "desconhecida";
}

// ----------------------------------------------------------------------
// Funções locais do script
// ----------------------------------------------------------------------

string FindLatestSdkPackage()
{
    var (_, stdout, _) = RunCommand("apt-cache", $"search ^{DotnetPkgPrefix}-[0-9]");

    var packages = stdout
        .Split('\n', StringSplitOptions.RemoveEmptyEntries)
        .Select(line => line.Split(' ')[0])
        .Where(name => Regex.IsMatch(name, $@"^{DotnetPkgPrefix}-\d+(\.\d+)?$"))
        .OrderBy(name => ExtractVersion(name))
        .ToList();

    if (packages.Count == 0)
    {
        Err($"Nenhum pacote {DotnetPkgPrefix}-* encontrado nos feeds do apt.");
        Err("Verifique se os repositórios do Ubuntu estão atualizados (sudo apt update).");
        Environment.Exit(1);
    }

    return packages.Last();
}

Version ExtractVersion(string packageName)
{
    var match = Regex.Match(packageName, @"(\d+)(?:\.(\d+))?$");
    int major = int.Parse(match.Groups[1].Value);
    int minor = match.Groups[2].Success ? int.Parse(match.Groups[2].Value) : 0;
    return new Version(major, minor);
}

string GetCandidateVersion(string package)
{
    var (_, stdout, _) = RunCommand("apt-cache", $"policy {package}");
    var match = Regex.Match(stdout, @"(Candidato|Candidate):\s*(\S+)");
    return match.Success ? match.Groups[2].Value : "desconhecida";
}

List<string> ListInstalledSdkPackages()
{
    var (_, stdout, _) = RunCommand("dpkg-query", "-W -f=${Package}\\n");
    return stdout
        .Split('\n', StringSplitOptions.RemoveEmptyEntries)
        .Where(name => Regex.IsMatch(name, $@"^{DotnetPkgPrefix}-\d+(\.\d+)?$"))
        .OrderBy(name => ExtractVersion(name))
        .ToList();
}

string GetInstalledVersion(string package)
{
    var (exitCode, stdout, _) = RunCommand("dpkg-query", $"-W -f=${{Version}} {package}");
    return exitCode == 0 ? stdout.Trim() : "?";
}

// ============================================================================
// Validações iniciais
// ============================================================================

RequireCommand("apt", "O comando 'apt' não está disponível. Este script requer Ubuntu.");
RequireCommand("apt-cache", "O comando 'apt-cache' não está disponível.");
RequireCommand("dpkg-query", "O comando 'dpkg-query' não está disponível.");

// ============================================================================
// Etapa 1 — Atualizar índice de pacotes
// ============================================================================

SectionTitle("Etapa 1 — Atualizando índice de pacotes");
Info("Executando apt update...");

var (updateExit, _, _) = RunCommand("apt", "update -y", useSudo: true, streamOutput: true);
if (updateExit != 0)
{
    Err("Falha ao atualizar o índice de pacotes.");
    Environment.Exit(1);
}
Success("Índice de pacotes atualizado.");

// ============================================================================
// Etapa 2 — Identificar versão mais recente disponível
// ============================================================================

SectionTitle("Etapa 2 — Identificando versão mais recente do .NET SDK");

string latestPkg = FindLatestSdkPackage();
Info($"Pacote mais recente disponível: {latestPkg}");

string latestAptVersion = GetCandidateVersion(latestPkg);

PrintField("Pacote", latestPkg);
PrintField("Versão", latestAptVersion);

// ============================================================================
// Etapa 3 — Desinstalar versões existentes
// ============================================================================

SectionTitle("Etapa 3 — Desinstalando versões existentes");

var installedPkgs = ListInstalledSdkPackages();

if (installedPkgs.Count == 0)
{
    Info($"Nenhum pacote {DotnetPkgPrefix}-* instalado. Nada a remover.");
}
else
{
    Info("Pacotes encontrados:");
    foreach (var pkg in installedPkgs)
    {
        string installedVer = GetInstalledVersion(pkg);
        PrintListItem($"{pkg} ({installedVer})");
    }

    Console.WriteLine();
    Info("Removendo...");

    string pkgList = string.Join(" ", installedPkgs);
    var (removeExit, _, _) = RunCommand("apt", $"remove -y {pkgList}", useSudo: true, streamOutput: true);
    if (removeExit != 0)
    {
        Err("Falha ao remover os pacotes existentes. Abortando.");
        Environment.Exit(1);
    }

    var (autoremoveExit, _, _) = RunCommand("apt", "autoremove -y", useSudo: true, streamOutput: true);
    if (autoremoveExit != 0)
    {
        Warn("Falha no autoremove. Pode haver dependências residuais.");
    }

    Success("Versões anteriores removidas.");
}

// ============================================================================
// Etapa 4 — Instalar versão mais recente
// ============================================================================

SectionTitle($"Etapa 4 — Instalando {latestPkg}");
Info($"Instalando {latestPkg}...");

var (installExit, _, _) = RunCommand("apt", $"install -y {latestPkg}", useSudo: true, streamOutput: true);
if (installExit != 0)
{
    Err($"Falha ao instalar {latestPkg}.");
    Environment.Exit(1);
}

CheckDotnet();
string newSdkVersion = GetSdkVersion();
Success($"SDK instalado com sucesso: {newSdkVersion}");

// ============================================================================
// Resumo final
// ============================================================================

SectionTitle("Resumo");

PrintField("SDK instalado", GetSdkVersion());
PrintField("Pacote", latestPkg);

Console.WriteLine();
Success("Atualização do .NET SDK concluída com sucesso.");