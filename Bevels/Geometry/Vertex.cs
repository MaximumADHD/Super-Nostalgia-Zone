using System.Drawing;
using RobloxFiles.DataTypes;

namespace BevelGenerator
{
    public class Vertex
    {
        public Vector3 Position;
        public Vector3 Normal;
        public Vector3 UV;

        public bool HasColor = false;
        public Color Color;
    }
}
