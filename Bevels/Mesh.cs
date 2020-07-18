using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

using RobloxFiles;
using RobloxFiles.DataTypes;

namespace BevelGenerator
{
    public class Bone : Instance
    {
        public int NameIndex;

        public short Id;
        public short ParentId;

        public float Unknown;
        public CFrame CFrame;

        public override string ToString()
        {
            return $"[Bone: {Name}]";
        }
    }

    public class Vertex
    {
        public Vector3 Position;
        public Vector3 Normal;
        public Vector3 UV;

        public Color? Color;
        public BoneWeights? Weights;
    }

    public class SkinData
    {
        public int FacesBegin;
        public int FacesLength;

        public int VertsBegin;
        public int VertsLength;

        public int NumBones;
        public short[] BoneIndexTree;
    }

    public struct BoneWeights
    {
        public byte[] Bones;
        public byte[] Weights;

        public override string ToString()
        {
            var bones = string.Join(", ", Bones);
            var weights = string.Join(", ", Weights);

            return $"{{Bones: [{bones}] | Weights: [{weights}]}}";
        }
    }

    public class Mesh
    {
        public int Version;
        public ushort NumMeshes = 0;

        public int NumVerts = 0;
        public List<Vertex> Verts;
        
        public int NumFaces = 0;
        public List<int[]> Faces;

        public ushort NumLODs;
        public List<int> LODs;

        public int NumBones = 0;
        public List<Bone> Bones;

        public int NumSkinData = 0;
        public List<SkinData> SkinData;

        public int NameTableSize = 0;
        public byte[] NameTable;

        public bool HasLODs => (Version >= 3);
        public bool HasSkinning => (Version >= 4);
        public bool HasVertexColors { get; private set; }

        private static Vector3 ReadVector3(BinaryReader reader)
        {
            float x = reader.ReadSingle(),
                  y = reader.ReadSingle(),
                  z = reader.ReadSingle();

            return new Vector3(x, y, z);
        }

        private static void LoadGeometry_Ascii(StringReader reader, Mesh mesh)
        {
            string header = reader.ReadLine();
            mesh.NumMeshes = 1;

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
        }

        private static void LoadGeometry_Binary(BinaryReader reader, Mesh mesh)
        {
            byte[] binVersion = reader.ReadBytes(13); // version x.xx\n
            var headerSize = reader.ReadUInt16();

            if (mesh.HasSkinning)
            {
                mesh.NumMeshes = reader.ReadUInt16();

                mesh.NumVerts = reader.ReadInt32();
                mesh.NumFaces = reader.ReadInt32();

                mesh.NumLODs = reader.ReadUInt16();
                mesh.NumBones = reader.ReadUInt16();

                mesh.NameTableSize = reader.ReadInt32();
                mesh.NumSkinData = reader.ReadInt32();
            }
            else
            {
                var sizeof_Vertex = reader.ReadByte();
                mesh.HasVertexColors = (sizeof_Vertex > 36);
                
                _ = reader.ReadByte();

                if (mesh.HasLODs)
                {
                    _ = reader.ReadUInt16();
                    mesh.NumLODs = reader.ReadUInt16();
                }

                if (mesh.NumLODs > 0)
                    mesh.NumMeshes = (ushort)(mesh.NumLODs - 1);
                else
                    mesh.NumMeshes = 1;

                mesh.NumVerts = reader.ReadInt32();
                mesh.NumFaces = reader.ReadInt32();

                mesh.NameTable = new byte[0];
            }

            mesh.LODs = new List<int>();
            mesh.Bones = new List<Bone>();
            mesh.Faces = new List<int[]>();
            mesh.Verts = new List<Vertex>();
            mesh.SkinData = new List<SkinData>();
            
            // Read Vertices
            for (int i = 0; i < mesh.NumVerts; i++)
            {
                var vert = new Vertex()
                {
                    Position = ReadVector3(reader),
                    Normal = ReadVector3(reader),
                    UV = ReadVector3(reader)
                };

                Color? color = null;

                if (mesh.HasVertexColors)
                {
                    int rgba = reader.ReadInt32();
                    color = Color.FromArgb(rgba << 24 | rgba >> 8);
                }
                
                vert.Color = color;
                mesh.Verts.Add(vert);
            }

            if (mesh.HasSkinning)
            {
                // Read Bone Weights?
                for (int i = 0; i < mesh.NumVerts; i++)
                {
                    var vert = mesh.Verts[i];

                    var weights = new BoneWeights()
                    {
                        Bones = reader.ReadBytes(4),
                        Weights = reader.ReadBytes(4)
                    };

                    vert.Weights = weights;
                }
            }

            // Read Faces
            for (int i = 0; i < mesh.NumFaces; i++)
            {
                int[] face = new int[3];

                for (int f = 0; f < 3; f++)
                    face[f] = reader.ReadInt32();

                mesh.Faces.Add(face);
            }

            if (mesh.HasLODs && mesh.NumLODs > 0)
            {
                // Read LOD ranges
                for (int i = 0; i < mesh.NumLODs; i++)
                {
                    int lod = reader.ReadInt32();
                    mesh.LODs.Add(lod);
                }
            }
            
            if (mesh.HasSkinning)
            {
                // Read Bones
                for (int i = 0; i < mesh.NumBones; i++)
                {
                    float[] cf = new float[12];

                    Bone bone = new Bone()
                    {
                        NameIndex = reader.ReadInt32(),
                        Id = reader.ReadInt16(),

                        ParentId = reader.ReadInt16(),
                        Unknown = reader.ReadSingle()
                    };

                    for (int m = 0; m < 12; m++)
                    {
                        int index = (m + 3) % 12;
                        cf[index] = reader.ReadSingle();
                    }

                    bone.CFrame = new CFrame(cf);
                    mesh.Bones.Add(bone);
                }

                // Read Bone Names & Parents
                var nameTable = reader.ReadBytes(mesh.NameTableSize);
                mesh.NameTable = nameTable;

                foreach (Bone bone in mesh.Bones)
                {
                    int index = bone.NameIndex;
                    int parentId = bone.ParentId;

                    var buffer = new List<byte>();

                    while (true)
                    {
                        byte next = nameTable[index];

                        if (next > 0)
                            index++;
                        else
                            break;

                        buffer.Add(next);
                    }

                    var result = buffer.ToArray();
                    bone.Name = Encoding.UTF8.GetString(result);

                    if (parentId >= 0)
                    {
                        var parent = mesh.Bones[parentId];
                        bone.Parent = parent;
                    }
                }

                // Read Skin Data?
                for (int p = 0; p < mesh.NumSkinData; p++)
                {
                    var skinData = new SkinData()
                    {
                        FacesBegin = reader.ReadInt32(),
                        FacesLength = reader.ReadInt32(),

                        VertsBegin = reader.ReadInt32(),
                        VertsLength = reader.ReadInt32(),

                        NumBones = reader.ReadInt32(),
                        BoneIndexTree = new short[26]
                    };

                    for (int i = 0; i < 26; i++)
                        skinData.BoneIndexTree[i] = reader.ReadInt16();

                    mesh.SkinData.Add(skinData);
                }
            }
            

            Debugger.Break();
        }

        public void AddLOD(Mesh lodMesh)
        {
            Verts.AddRange(lodMesh.Verts);

            Faces.AddRange
            (
                lodMesh.Faces.Select
                (
                    face => face
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
            const byte   VertSize   = 40;
            const byte   FaceSize   = 12;
            const ushort LOD_Size   = 4;
            
            byte[] VersionHeader = Encoding.UTF8.GetBytes("version 3.00\n");

            if (NumLODs == 0)
            {
                NumLODs = 2;
                LODs = new List<int> { 0, NumFaces };
            }

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

                    if (vertex.Color.HasValue)
                    {
                        var color = vertex.Color.Value;
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

            var uvTable = new List<Vector3>();
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
                    string action = buffer[0];

                    switch (action)
                    {
                        case "v":
                        case "vn":
                        case "vt":
                        {
                            float[] input = buffer
                                .Skip(1)
                                .Select(float.Parse)
                                .ToArray();

                            var value = new Vector3(input);
                            List<Vector3> target = null;

                            switch (action)
                            {
                                case "v":
                                {
                                    target = posTable;
                                    break;
                                }
                                case "vn":
                                {
                                    target = normTable;
                                    break;
                                }
                                case "vt":
                                {
                                    target = uvTable;
                                    break;
                                }
                            }

                            target.Add(value);
                            break;
                        }
                        case "f":
                        {
                            int[] face = new int[3];

                            for (int i = 0; i < 3; i++)
                            {
                                string faceDef = buffer[i + 1];
                                string[] indices = faceDef.Split('/');

                                int uvId = int.Parse(indices[1]) - 1;
                                int posId = int.Parse(indices[0]) - 1;
                                int normId = int.Parse(indices[2]) - 1;

                                string key = $"{posId}/{uvId}/{normId}";

                                if (!vertexLookup.ContainsKey(key))
                                {
                                    int faceId = mesh.NumVerts++;
                                    vertexLookup.Add(key, faceId);

                                    Vertex vert = new Vertex()
                                    {
                                        Position = posTable[posId],
                                        Normal = normTable[normId],
                                        UV = uvTable[uvId]
                                    };

                                    mesh.Verts.Add(vert);
                                }

                                face[i] = vertexLookup[key];
                            }

                            mesh.Faces.Add(face);
                            mesh.NumFaces++;

                            break;
                        }   
                    }
                }
            }

            return mesh;
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
            else
            {
                MemoryStream stream = new MemoryStream(data);

                using (BinaryReader reader = new BinaryReader(stream))
                    LoadGeometry_Binary(reader, mesh);

                disposeThis = stream;
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
            Mesh result;

            using (FileStream meshStream = File.OpenRead(path))
                result = FromStream(meshStream);

            return result;
        }
    }
}