using System.IO;
using Microsoft.Win32;

public static class RegistryHelper
{
    public static RegistryKey GetSubKey(this RegistryKey key, params string[] path)
    {
        string constructedPath = Path.Combine(path);
        return key.CreateSubKey(constructedPath, RegistryKeyPermissionCheck.ReadWriteSubTree, RegistryOptions.None);
    }

    public static string GetString(this RegistryKey key, string name)
    {
        var result = key.GetValue(name, "");
        return result.ToString();
    }
}