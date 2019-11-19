using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

using RobloxFiles.DataTypes;

namespace BevelGenerator
{
    public class Mesh
    {
        public int Version;

        public int NumVerts = 0;
        public List<Vertex> Verts;

        public int NumFaces = 0;
        public List<int[]> Faces;

        public ushort NumLODs = 0;
        public List<int> LODs;

        private static Vector3 ReadVector3(BinaryReader reader)
        {
            float x = reader.ReadSingle(),
                  y = reader.ReadSingle(),
                  z = reader.ReadSingle();

            return new Vector3(x, y, z);
        }

        private static Mesh CheckLOD(Mesh mesh)
        {
            if (mesh.NumLODs == 0)
            {
                mesh.NumLODs = 2;
                mesh.LODs = new List<int> { 0, mesh.NumFaces };
            }

            return mesh;
        }

        private static void LoadGeometry_Ascii(StringReader reader, Mesh mesh)
        {
            string header = reader.ReadLine();

            if (!header.StartsWith("version 1"))
                throw new Exception("Expected version 1 header, got: " + header);

            string version = header.Substring(8);
            float vertScale = (version == "1.00" ? 0.5f : 1);

            if (int.TryParse(reader.ReadLine(), out mesh.NumFaces))
                mesh.NumVerts = mesh.NumFaces * 3;
            else
                throw new Exception("Expected 2nd line to be the polygon count.");

            mesh.Faces = new List<int[]>();
            mesh.Verts = new List<Vertex>();

            string polyBuffer = reader.ReadLine();
            MatchCollection matches = Regex.Matches(polyBuffer, @"\[(.*?)\]");

            int face = 0;
            int index = 0;
            int target = 0;

            var vertex = new Vertex();

            foreach (Match m in matches)
            {
                string vectorStr = m.Groups[1].ToString();

                float[] coords = vectorStr.Split(',')
                    .Select(coord => Format.ParseFloat(coord))
                    .ToArray();

                if (target == 0)
                    vertex.Position = new Vector3(coords) * vertScale;
                else if (target == 1)
                    vertex.Normal = new Vector3(coords);
                else if (target == 2)
                    vertex.UV = new Vector3(coords[0], 1 - coords[1], 0);

                target = (target + 1) % 3;

                if (target == 0)
                {
                    mesh.Verts.Add(vertex);
                    vertex = new Vertex();

                    if (index % 3 == 0)
                    {
                        int v = face * 3;
                        int[] faceDef = new int[3] { v, v + 1, v + 2 };
                        mesh.Faces.Add(faceDef);
                    }
                }
            }

            CheckLOD(mesh);
        }

        private static void LoadGeometry_Binary(BinaryReader reader, Mesh mesh)
        {
            byte[] binVersion = reader.ReadBytes(13);
            var headerSize = reader.ReadUInt16();

            var vertSize = reader.ReadByte();
            var faceSize = reader.ReadByte();
            
            if (mesh.Version >= 3)
            {
                var lodRangeSize = reader.ReadUInt16();
                mesh.NumLODs = reader.ReadUInt16();
            }

            mesh.NumVerts = reader.ReadInt32();
            mesh.NumFaces = reader.ReadInt32();

            mesh.LODs = new List<int>();
            mesh.Faces = new List<int[]>();
            mesh.Verts = new List<Vertex>();
            
            for (int i = 0; i < mesh.NumVerts; i++)
            {
                var vert = new Vertex()
                {
                    Position = ReadVector3(reader),
                    Normal = ReadVector3(reader),
                    UV = ReadVector3(reader)
                };

                if (vertSize > 36)
                {
                    int rgba = reader.ReadInt32();  
                    int argb = (rgba << 24 | rgba >> 8);

                    vert.Color = Color.FromArgb(argb);
                    vert.HasColor = true;
                }

                mesh.Verts.Add(vert);
            }

            for (int i = 0; i < mesh.NumFaces; i++)
            {
                int[] face = new int[3];

                for (int f = 0; f < 3; f++)
                    face[f] = reader.ReadInt32();

                mesh.Faces.Add(face);
            }

            if (mesh.NumLODs > 0)
            {
                for (int i = 0; i < mesh.NumLODs; i++)
                {
                    int lod = reader.ReadInt32();
                    mesh.LODs.Add(lod);
                }
            }
            
            CheckLOD(mesh);
        }

        public void AddLOD(Mesh lodMesh)
        {
            Verts.AddRange(lodMesh.Verts);

            Faces.AddRange(lodMesh.Faces
                .Select(face => face
                    .Select(i => i + NumVerts)
                    .ToArray()
                )
            );

            NumVerts = Verts.Count;
            NumFaces = Faces.Count;

            LODs.Add(NumFaces);
            NumLODs += 1;
        }

        public void Save(Stream stream)
        {
            const ushort HeaderSize = 16;
            const byte   VertSize = 40;
            const byte   FaceSize = 12;
            const ushort LOD_Size = 4;
            
            byte[] VersionHeader = Encoding.ASCII.GetBytes("version 3.00\n");

            using (BinaryWriter writer = new BinaryWriter(stream))
            {
                writer.Write(VersionHeader);
                writer.Write(HeaderSize);

                writer.Write(VertSize);
                writer.Write(FaceSize);
                writer.Write(LOD_Size);

                writer.Write(NumLODs);
                writer.Write(NumVerts);
                writer.Write(NumFaces);

                for (int i = 0; i < NumVerts; i++)
                {
                    Vertex vertex = Verts[i];

                    Vector3 pos = vertex.Position;
                    writer.Write(pos.X);
                    writer.Write(pos.Y);
                    writer.Write(pos.Z);

                    Vector3 norm = vertex.Normal;
                    writer.Write(norm.X);
                    writer.Write(norm.Y);
                    writer.Write(norm.Z);

                    Vector3 uv = vertex.UV;
                    writer.Write(uv.X);
                    writer.Write(uv.Y);
                    writer.Write(uv.Z);

                    if (vertex.HasColor)
                    {
                        var color = vertex.Color;
                        int argb = color.ToArgb();

                        int rgba = (argb << 8 | argb >> 24);
                        writer.Write(rgba);
                    }
                    else
                    {
                        writer.Write(-1);
                    }
                }

                for (int i = 0; i < NumFaces; i++)
                {
                    int[] faces = Faces[i];

                    for (int f = 0; f < 3; f++)
                    {
                        int face = faces[f];
                        writer.Write(face);
                    }
                }

                for (int i = 0; i < NumLODs; i++)
                {
                    int lod = LODs[i];
                    writer.Write(lod);
                }
            }
        }

        public static Mesh FromObjFile(string filePath)
        {
            string contents = File.ReadAllText(filePath);

            Mesh mesh = new Mesh()
            {
                Version = 3,
                Faces = new List<int[]>(),
                Verts = new List<Vertex>()
            };

            var posTable = new List<Vector3>();
            var normTable = new List<Vector3>();

            var vertexLookup = new Dictionary<string, int>();

            using (StringReader reader = new StringReader(contents))
            {
                string line;

                while ((line = reader.ReadLine()) != null)
                {
                    if (line.Length == 0)
                        continue;

                    string[] buffer = line.Split(' ');
                    string cmd = buffer[0];

                    if (cmd == "v" || cmd == "vn")
                    {
                        float[] input = buffer
                            .Skip(1)
                            .Select(float.Parse)
                            .ToArray();

                        var value = new Vector3(input);
                        var target = (cmd == "v" ? posTable : normTable);

                        target.Add(value);
                    }
                    else if (cmd == "f")
                    {
                        int[] face = new int[3];

                        for (int i = 0; i < 3; i++)
                        {
                            string faceDef = buffer[i + 1];
                            string[] indices = faceDef.Split('/');

                            int posId = int.Parse(indices[0]) - 1;
                            int normId = int.Parse(indices[2]) - 1;

                            string key = $"{posId}/{normId}";

                            if (!vertexLookup.ContainsKey(key))
                            {
                                int faceId = mesh.NumVerts++;
                                vertexLookup.Add(key, faceId);

                                Vertex vert = new Vertex()
                                {
                                    Position = posTable[posId],
                                    Normal = normTable[normId],
                                    UV = new Vector3()
                                };

                                mesh.Verts.Add(vert);
                            }

                            face[i] = vertexLookup[key];
                        }

                        mesh.Faces.Add(face);
                        mesh.NumFaces++;
                    }
                }
            }

            return CheckLOD(mesh);
        }

        public static Mesh FromBuffer(byte[] data)
        {
            string file = Encoding.ASCII.GetString(data);

            if (!file.StartsWith("version "))
                throw new Exception("Invalid .mesh header!");

            string versionStr = file.Substring(8, 4);
            double version = Format.ParseDouble(versionStr);

            Mesh mesh = new Mesh();
            mesh.Version = (int)version;

            IDisposable disposeThis;

            if (mesh.Version == 1)
            {
                StringReader buffer = new StringReader(file);
                LoadGeometry_Ascii(buffer, mesh);

                disposeThis = buffer;
            }
            else if (mesh.Version == 2 || mesh.Version == 3)
            {
                MemoryStream stream = new MemoryStream(data);

                using (BinaryReader reader = new BinaryReader(stream))
                    LoadGeometry_Binary(reader, mesh);

                disposeThis = stream;
            }
            else
            {
                throw new Exception($"Unknown .mesh file version: {version}");
            }

            disposeThis.Dispose();
            disposeThis = null;

            return mesh;
        }

        public static Mesh FromStream(Stream stream)
        {
            byte[] data;

            using (MemoryStream buffer = new MemoryStream())
            {
                stream.CopyTo(buffer);
                data = buffer.ToArray();
            }

            return FromBuffer(data);
        }

        public static Mesh FromFile(string path)
        {
            using (FileStream meshStream = File.OpenRead(path))
            {
                return FromStream(meshStream);
            }
        }
    }
}