using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Windows.Forms;

using RobloxFiles;
using RobloxFiles.Enums;
using RobloxFiles.DataTypes;

using Microsoft.Win32;
using System.Text.RegularExpressions;

namespace BevelGenerator
{
    class Program
    {
        private const string uploadNewMesh = "https://data.roblox.com/ide/publish/UploadNewMesh";
        private static string bevelCacheDir;

        private static string studioCookies = "";
        private static string xCsrfToken = "FETCH";
        
        private static Random rng = new Random();

        static void addNoise(ref float value)
        {
            float noise = (float)(-1e-6 + (rng.NextDouble() * 2e-6));
            value += noise;
        }

        static Mesh CreateBevelMesh(Vector3 size, bool reupload = false)
        {
            byte[] baseMesh = Properties.Resources.Bevels;
            Mesh bevels = Mesh.FromBuffer(baseMesh);

            float sx = (size.X - 1f) / 2f,
                  sy = (size.Y - 1f) / 2f,
                  sz = (size.Z - 1f) / 2f;

            if (reupload)
            {
                addNoise(ref sx);
                addNoise(ref sy);
                addNoise(ref sz);
            }

            foreach (Vertex vert in bevels.Verts)
            {
                Vector3 pos = vert.Position;

                float x = pos.X;
                x += (x >= 0 ? sx : -sx);

                float y = pos.Y;
                y += (y >= 0 ? sy : -sy);

                float z = pos.Z;
                z += (z >= 0 ? sz : -sz);

                vert.Position = new Vector3(x, y, z);
            }

            return bevels;
        }
        
        static long UploadMesh(Mesh mesh, string name, string desc)
        {
            string uploadName = WebUtility.UrlEncode(name);
            string uploadDesc = WebUtility.UrlEncode(desc);

            string address = $"{uploadNewMesh}?name={uploadName}&description={uploadDesc}";
            var request = WebRequest.Create(address) as HttpWebRequest;

            request.Method = "POST";
            request.ContentType = "*/*";
            request.UserAgent = "RobloxStudio/WinInet";

            request.Headers.Set("Cookie", studioCookies);
            request.Headers.Set("X-CSRF-TOKEN", xCsrfToken);

            using (Stream writeStream = request.GetRequestStream())
            {
                mesh.Save(writeStream);
                writeStream.Close();
            }

            HttpWebResponse response = null;

            try
            {
                var result = request.GetResponse();
                response = result as HttpWebResponse;
            }
            catch (WebException e)
            {
                response = e.Response as HttpWebResponse;

                if (response.StatusDescription.Contains("XSRF"))
                {
                    // Update the X-CSRF-TOKEN.
                    xCsrfToken = response.Headers.Get("X-CSRF-TOKEN");

                    // Retry the upload.
                    return UploadMesh(mesh, name, desc);
                }
                else
                {
                    throw e;
                }
            }

            long assetId = -1;

            using (Stream stream = response.GetResponseStream())
            {
                byte[] data;

                using (MemoryStream buffer = new MemoryStream())
                {
                    stream.CopyTo(buffer);
                    data = buffer.ToArray();
                }

                string strAssetId = Encoding.ASCII.GetString(data);
                assetId = long.Parse(strAssetId);
            }

            return assetId;
        }

        static string ProcessInput(string input)
        {
            float[] xyz;

            try
            {
                var inputData = input.Split('~', ',', ' ')
                    .Select(str => str.Trim())
                    .Where(str => str.Length > 0)
                    .Select(str => Format.ParseFloat(str));

                if (inputData.Count() != 3)
                    throw new Exception();

                xyz = inputData.ToArray();
                input = Format.FormatFloats(xyz);
            }
            catch
            {
                Console.WriteLine("\tInvalid input: {0}", input);
                return null;
            }

            string name = $"Bevel{input}";
            const string desc = "[AUTO-GENERATED BEVEL MESH]";
            string cached = Path.Combine(bevelCacheDir, $"{name}.txt");

            bool exists = File.Exists(cached);
            bool moderated = false;
            
            if (exists)
            {
                string contents = File.ReadAllText(cached);
                moderated = (contents.ToLower() == "moderated");
            }

            if (moderated || !exists)
            {
                Vector3 size = new Vector3(xyz);
                Mesh mesh = CreateBevelMesh(size, moderated);

                Console.WriteLine("\tUploading {0}...", name);
                long assetId = UploadMesh(mesh, name, desc);

                File.WriteAllText(cached, assetId.ToString());
            }

            string result = "rbxassetid://" + File.ReadAllText(cached);
            Console.WriteLine("  Result -> {0} (copied to clipboard)", result);

            return result;
        }

        static void ProcessModelFile(string filePath)
        {
            RobloxFile file = RobloxFile.Open(filePath);
            var exportBin = file.FindFirstChild<Folder>("ExportBin");

            if (exportBin != null)
                exportBin.Name = "BevelCache";
            else
                return;

            var unions = exportBin.GetChildrenOfType<UnionOperation>();

            for (int i = 0; i < unions.Length; i++)
            {
                UnionOperation union = unions[i];
                string name = union.Name;

                Console.WriteLine("Working on {0}... ({1}/{2})", union.Name, i, unions.Length);
                string meshId = ProcessInput(name);

                if (meshId == null)
                    continue;

                MeshPart bevelMesh = new MeshPart()
                {
                    Name = name,
                    MeshId = meshId,

                    Size = union.Size,
                    InitialSize = union.InitialSize,
                    RenderFidelity = RenderFidelity.Automatic,

                    PhysicsData = union.PhysicsData,
                    CollisionFidelity = CollisionFidelity.Box,
                    PhysicalConfigData = union.PhysicalConfigData,
                };

                foreach (string tag in union.Tags)
                    bevelMesh.Tags.Add(tag);

                bevelMesh.Parent = exportBin;
                union.Parent = null;
            }

            using (FileStream export = File.OpenWrite(filePath))
                file.Save(export);

            if (file is XmlRobloxFile)
                Process.Start(filePath);

            Console.WriteLine("Finished processing order!");
            Console.WriteLine("Press any key to continue...");

            Console.ReadKey();
            Console.Clear();
        }
        
        static Mesh PortObjFile(FileInfo info)
        {
            Console.WriteLine("Reading obj file...");

            string objPath = info.FullName;
            Mesh mesh = Mesh.FromObjFile(objPath);

            Console.WriteLine("Writing mesh file...");

            string extension = info.Extension;
            string filePath = objPath.Replace(extension, ".mesh");

            using (FileStream file = File.OpenWrite(filePath))
            {
                file.SetLength(0);
                mesh.Save(file);
            }

            return mesh;
        }

        static void ProcessFileArg(string filePath)
        {
            FileInfo info = new FileInfo(filePath);

            switch (info.Extension)
            {
                case ".obj":
                    Mesh export = PortObjFile(info);

                    Console.Write("Would you like to upload this mesh? (y/n): ");
                    string answer = Console.ReadLine();

                    if (answer.ToLower()[0] == 'y')
                    {
                        Console.Write("Enter a name for this mesh: ");
                        string name = Console.ReadLine();

                        Console.Write("Enter a description for this mesh: ");
                        string desc = Console.ReadLine();

                        Console.WriteLine("Uploading mesh...");
                        long result = 0;

                        try
                        {
                            result = UploadMesh(export, name, desc);
                        }
                        catch (Exception e)
                        {
                            Console.WriteLine($"An error occurred while uploading: {e.Message}");
                        }
                        
                        if (result > 0)
                        {
                            Clipboard.SetText($"rbxassetid://{result}");
                            Console.WriteLine($"Result -> rbxassetid://{result} (copied to clipboard)");
                        }

                        Debugger.Break();
                    }

                    break;
                case ".bin":
                case ".mesh":
                    Mesh import = Mesh.FromFile(filePath);
                    Debugger.Break();

                    break;
                default:
                    ProcessModelFile(filePath);
                    break;
            }
        }

        [STAThread]
        static void Main(string[] args)
        {
            string localAppData = Environment.GetEnvironmentVariable("LocalAppData");
            bevelCacheDir = Path.Combine(localAppData, "BevelCache");

            if (!Directory.Exists(bevelCacheDir))
                Directory.CreateDirectory(bevelCacheDir);

            RegistryKey robloxCookies = Registry.CurrentUser.GetSubKey
            (
                "SOFTWARE", "Roblox",
                "RobloxStudioBrowser",
                "roblox.com"
            );

            foreach (string name in robloxCookies.GetValueNames())
            {
                string cookie = robloxCookies.GetString(name);
                Match match = Regex.Match(cookie, "COOK::<([^>]*)>");

                if (match.Groups.Count > 1)
                {
                    cookie = match.Groups[1].Value;

                    if (studioCookies.Length > 0)
                        studioCookies += "; ";

                    studioCookies += $"{name}={cookie}";
                }
            }

            if (args.Length > 0)
            {
                string filePath = args[0];
                ProcessFileArg(filePath);
            }

            Console.WriteLine("Enter bevel sizes in format: 'X ~ Y ~ Z' to generate them as .mesh files!");
            Console.WriteLine("       (Also accepts format: 'X, Y, Z' and 'X Y Z')");

            while (true)
            {
                Console.Write("> ");
                string inputLine = Console.ReadLine();

                if (inputLine == "exit")
                    break;

                string assetId = ProcessInput(inputLine);
                Clipboard.SetText(assetId);
            }
        }
    }
}
