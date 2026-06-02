# NormalPaint

## Índice
1. [Autoras](#autoras)
2. [Resumen](#resumen)
3. [Instalación y uso](#instalación-y-uso)
4. [Introducción](#introducción)
5. [Planteamiento del proyecto](#planteamiento-del-proyecto)
6. [Estructura](#estructura)
7. [Implementación](#implementación)
8. [Pruebas y métricas](#pruebas-y-métricas)
9. [Conclusiones](#conclusiones)
10. [Licencia](#licencia)
11. [Referencias](#referencias)

## Autoras
- Nieves Alonso Gilsanz [@nievesag](https://github.com/nievesag)
- Cynthia Tristán Álvarez [@cyntrist](https://github.com/cyntrist)

## Resumen
El proyecto consiste en una aplicación de pintura en 3D en tiempo real donde se podrá importar modelos y pintar sobre ellos. Además, se podrá elegir el pincel con el que pintar y su tamaño, el color con el que pintar y sobre qué «capa» pintar: textura albedo, mapa de normales o ambas a la vez.

## Instalación y uso
Todo el contenido del proyecto está disponible en este repositorio, con **Godot Engine v4.6.2.** o posterior siendo capaces de bajar todos los recursos necesarios y editar el proyecto.

## Introducción
Este proyecto corresponde a la práctica final de la asignatura de Iluminación y Materiales del Grado en Desarrollo de Videojuegos de la UCM del curso 2025-2026. Este prototipo sirve para poner en práctica los conocimientos de la asignatura a través de su exploración de los mapas de normales, el procesado de texturas y materiales en motores actuales y la programación de shaders de cómputo en GPU.

## Estructura
### Estructura del proyecto
Los recursos que conforman el proyecto están organizados de esta forma:

* **Fonts**. Fuentes utilizadas en el proyecto.
* **Images**. Imágenes utilizadas en interfaces, máscaras de pincel y texturas.
* **Materials**. Material de normales y material de textura albedo del modelo cargado actualmente.
  * **Shaders**. Shader de cómputo y otros shaders usados durante el desarrollo.
* **Mesh**. Modelo cargado actualmente.
* **Prefabs**. Prefabricados preparados para instanciarse durante la simulación.
* **Scenes**. La escena principal.
* **Scripts**. Todas las clases con el código organizado en una jerarquía de carpetas.
* **Textures**. Imágenes importadas como texturas utilizadas en interfaces, máscaras de pincel y texturas.

#### Jerarquía de recursos
```text
assets
├── fonts
├── images
│   ├── brushes
│   ├── cursor
│   └── normals
├── materials
│   └── shaders
├── mesh
├── scenes
├── scripts
│   └── autoloads
└── textures
    ├── brushes
    └── normals
```

### Estructura de las escenas
Hay una única escena en el prototipo donde se podrán realizar todas las acciones:

## Planteamiento del proyecto
Las características principales del prototipo son:

* Se podrá inspeccionar un modelo cargado con una cámara que permite: acercarse y alejarse del modelo, orbitar a su alrededor, rotar, panear, resetearse a su posición inicial, y volver a establecer un objetivo.

* Se podrá alternar la vista del texturizado del modelo entre: vista estándar y vista de solo mapa de normales.

* Para pintar sobre la textura se seleccionará un pincel, su tamaño y el color que se va a usar para pintar en cada capa. La interfaz contará con opciones para todo esto.

* Se podrá pintar sobre ambas capas en tiempo real, permitiendo elegir si pintas solo en una de las dos o en ambas, la textura del mapa de normales se interpretará como tal haciendo que los trazos reaccionen a la luz.

* Se podrán importar y exportar modelos nuevos, con sus texturas, para probar el prototipo.

## Implementación
La implementación del prototipo ha abarcado, principalmente, cuatro retos: el procesado del input de un usuario, actualizar una textura según ese input procesado, gestionar las diferentes capas, y optimizar el pintado.

### 1. Procesamiento del input y obtención de UVs
El hecho de pintar sobre un modelo implica pintar sobre la textura que le envuelve, que es la que define cómo se ve, entonces, cuando un usuario se dispone a pintar sobre un modelo, hace clic y efectúa un trazo, surge la pregunta: ¿cómo sabemos exactamente en qué punto de la textura debemos pintar, de manera interna?

Motores como Unity ofrecen una funcionalidad para esto con el método [RaycastHit.textureCoord](https://docs.unity3d.com/ScriptReference/RaycastHit-textureCoord.html), pero al estar realizando el proyecto en Godot, que no ofrece un método como este, hemos tenido que realizar el cálculo a mano.

Se empieza lanzando un rayo desde la cámara con longitud infinita en el momento del clic, si se ha colisionado con algo se intenta acceder a la mesh del objeto colisionado, gracias a la herramienta [MeshDataTool](https://docs.godotengine.org/en/stable/classes/class_meshdatatool.html) de Godot que proporciona acceso a los vértices, índices, normales, caras, UVs, etc. de la malla y al propio motor de físicas de Godot que da acceso al índice de la cara colisionada por el rayo se puede realizar el cálculo necesario para objener las UVs de la textura correspondientes a esa colisión en la malla.

Se puede denominar a esto entonces como «primer paso» en la obtención de UVs.

![UV](https://github.com/nievesag/NormalPaint/blob/main/docs/UV.png)

El «segundo paso» corresponde a los cálculos matemáticos. El prototipo funciona con mallas trianguladas, que aseguran que cada cara que compone a la malla es un triángulo.

Como ya tenemos acceso a la cara triangular colisionada podemos entonces acceder a los vértices que la conforman y con estos datos calcular las UVs haciendo uso de las **coordenadas baricéntricas**: para cualquier punto P dentro de un triángulo ABC podemos encontrar 3 *factores de interpolación* que funcionan como equivalentes a las razones de las áreas de PBC, PCA y PAB con respecto al área del triángulo de referencia ABC, de tal manera que, siendo (bx,by,bz) las coordenadas baricéntricas de P con respecto al triángulo ABC:
```
P = bx·A + by·B + bz·C
1 = bx + by + bz
```
Con este razonamiento se puede calcular:
```
// vectores a cada uno de los vértices
var v0 := b - a
var v1 := c - a
var v2 := p - a

// cálculo del baricentro
var d00 := v0.dot(v0)
var d01 := v0.dot(v1)
var d11 := v1.dot(v1)
var d20 := v2.dot(v0)
var d21 := v2.dot(v1)

var denom := d00 * d11 - d01 * d01

var v: float = (d11 * d20 - d01 * d21) / denom
var w: float = (d00 * d21 - d01 * d20) / denom
var u: float = 1.0 - v - w

var bc: Vector3 = Vector3(u, v, w)
```
Una vez se ha obtenido el baricentro el «tercer paso» resulta trivial:
```
// se multiplican los valores de los factores de interpolación asociados a cada vértice y se suma todo
var uv_from_face: Vector2 = uv0 * bc.x + uv1 * bc.y + uv2 * bc.z
```
Cuando se ha obtenido la coordenada de textura en la que se deberá pintar según el input procesado se puede pasar a la gestión del trazo en sí.

### 2. Gestión de un trazo
Los pinceles se procesan como máscaras de color, con la silueta de la forma del pincel en blanco y el fondo en negro. Entonces, para gestionar un trazo en una textura es importante conocer qué máscara de pincel se está usando, su tamaño, el color con el que se debe pintar y sobre qué capa se está pintando, que decidirá la textura que ha de ser modificada (textura albedo o mapa de normales).

Se detalla a continuación el método implementado para gestionar un trazo por cpu.

TODO

### 3. Materiales y capas

TODO

### 4. Optimización
Para acelerar el cálculo de la gestión de un trazo, el actualizar los píxeles de la textura deseada según una máscara en una posición de UVs dada, se hace uso de un shader de cómputo el cual permite el procesado de datos por gpu de manera que se pueden paralelizar y acelerar los cálculos. 

Para poder hacer uso de estos primero hay que preparar una puesta en marcha en gdscript, para ello lo primero es acceder al [RenderingDevice](https://docs.godotengine.org/en/stable/classes/class_renderingdevice.html) global que proporciona una abastracción de APIs gráficas de bajo nivel como Vulkan o DirectX, a través de él se podrá invocar al shader en glsl que realizará los cálculos, y a este se le pasarán datos en formato buffer para procesarlos, RenderingDevice también facilita su creación e inicialización y la asignación de los *work groups*, agrupaciones de hilos capaces de cooperar entre sí y ejecutarse en paralelo.

De esta manera se inicializa un shader de cómputo para poder usarlo más adelante.
```
// carga shader que hará los cálculos
var shader_file: RDShaderFile = load("res://materials/shaders/compute_shader.glsl")
// compila shader
var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
shader = rd.shader_create_from_spirv(shader_spirv)
// crea shader pipeline
pipeline = rd.compute_pipeline_create(shader)
```
El shader necesitará tener acceso, a la imagen de la textura y a la imagen de la máscara del pincel, así como otros parámetros usados en el cálculo del pintado de un trazo.

Para poder pasar las imágenes hay que procesarlas correctamente asegurando que no cuentan con mipmaps y que su formato es RGBAF, con ello se puede pasar a crear el [RID](https://docs.godotengine.org/es/4.x/classes/class_rid.html), o id del recurso, con el que podrá ser identificado a la hora de crear el uniform que ahora sí serán los datos que le pasamos al shader. 
```
// creación de una imagen
// comprobaciones de formato
var mask_image: Image = Global.brush_mask.duplicate()
mask_image.convert(Image.FORMAT_RGBAF)
if mask_image.has_mipmaps():
  mask_image.clear_mipmaps()

// RID
var mask_view := RDTextureView.new()
var mask_format := RDTextureFormat.new()
mask_format.width = mask_image.get_width()
mask_format.height = mask_image.get_height()
mask_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
mask_format.usage_bits = (
  RenderingDevice.TEXTURE_USAGE_STORAGE_BIT +
  RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT +
  RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT +
  RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
)

_free_rid_if_valid(_mask_rid)
_mask_rid = rd.texture_create(mask_format, mask_view, [mask_image.get_data()])

// creación del uniform
var mask_uniform: RDUniform = RDUniform.new()
mask_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
mask_uniform.binding = 1 // cada uniform tiene un binding único
mask_uniform.add_id(_mask_rid)
```
Pasar datos simples es más sencillo ya que vale con llenar el RID del [PackedByteArray](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html) con los datos necesarios y asociar este de nuevo a un uniform que se adjuntará al shader.
```
// creación de un buffer
var _params_buffer: RID = rd.storage_buffer_create(empty_params.size(), empty_params)

// creación del uniform
var parameter_uniform: RDUniform = RDUniform.new()
parameter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
parameter_uniform.binding = 0
parameter_uniform.add_id(_params_buffer)
```

A estos parámetros se accede desde el glsl tal que:
```
// se caracterizan por su binding
layout(set = 0, binding = 0, std430) readonly buffer parameters {
  // se pueden acceder a todos los parámetros pasados
    float width;
    float height;
    float mask_w;
    float mask_h;
    float cx;
    float cy;
    float diameter;
    float radius;
    float brush_strength;
}
params;

layout(set = 0, binding = 1, rgba32f) uniform image2D mask; // mascara
```
Para empezar a computar el shader se siguen los siguientes pasos:
* Se empiezan a grabar los comandos para la GPU
```
var compute_list: int = rd.compute_list_begin()
```
* Bindea la pipeline, informa a la GPU de qué shader tiene que usar
```
rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
```
* Bindea el set de uniforms con la información que queremos pasar a nuestro shader
```
rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
```
* Dispatchs con los work groups (XxYxZ)
```
var groups_x := int(ceil(diameter / 32.0))
var groups_y := int(ceil(diameter / 32.0))
rd.compute_list_dispatch(compute_list, groups_x, groups_y, 1)
```
* Informa a la GPU de que hemos acabado con esta tarea
```
rd.compute_list_end()
```

El shader se computa una vez por cada hilo, 

TODO 

y que se puede obviar el doble for que se ejecutaba en la versión de CPU. Pudiendo acceder a la x y la a la y locales de la máscara tal que así:
```
ivec2 local = ivec2(gl_GlobalInvocationID.xy);
```
![WORK](https://github.com/nievesag/NormalPaint/blob/main/docs/work.png)
El resto del código se basa en la versión de CPU y lo adapta a la paralelización con el shader basándose en este criterio.

## Pruebas y métricas
### Métricas tomadas

### Vídeo
- [Vídeo demostración]()

## Conclusiones

## Licencia
Nieves Alonso Gilsanz y Cynthia Tristán Álvarez, autoras de la documentación, código y recursos de este trabajo, concedemos permiso permanente para utilizar este material, con fines educativos o de investigación; ya sea para obtener datos agregados de forma anónima como para utilizarlo total o parcialmente reconociendo expresamente nuestra autoría.

## Referencias
A continuación se detallan todas las referencias bibliográficas, o de otro tipo utilizdas para realizar este prototipo. Los recursos de terceros que se han utilizados son de uso público.

[^1]: Cody Gindy. [*Making 3D animation look painterly (it's easier than you think)*](https://www.youtube.com/watch?v=s8N00rjil_4). Cody Gindy. Youtube. 2023.

[^2]: Crigz Vs Game Dev. [*How to use Compute Shaders in Godot 4*](https://www.youtube.com/watch?v=5CKvGYqagyI). Crigz Vs Game Dev. Youtube. 2022.

[^3]: Alfred Reinold Baudisch. [*Godot Engine In-game Splat Map Texture Painting (Dirt Removal Effect)*](https://github.com/alfredbaudisch/GodotRuntimeTextureSplatMapPainting/tree/master). 2022.

[^4]: DevPoodle. [*A Guide to Using Compute Shaders in Godot*](https://www.youtube.com/watch?v=ry7bv7BY56c). DevPoodle. Youtube. 2025.

[^5]: Godot Engine 4.6 documentation in English. [*Using compute shaders*](https://docs.godotengine.org/en/stable/tutorials/shaders/compute_shaders.html).

[^6]: Godot Engine 4.6 documentation in English. [*Shading language*](https://docs.godotengine.org/en/4.4/tutorials/shaders/shader_reference/shading_language.html).

[^7]: Godot Engine 4.6 documentation in English. [*Ray-casting*](https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html#d-ray-casting-from-screen).

[^8]: Burt, M. Hollós, R. [*godot-vertex-painter*](https://github.com/bikemurt/godot-vertex-painter). 2024.

[^9]: Wikipedia Contributors. [*Barycentric coordinate system*](https://en.wikipedia.org/wiki/Barycentric_coordinate_system). Wikipedia.

[^10]: Wikipedia Contributors. [*Barycentric coordinate system*](https://en.wikipedia.org/wiki/Barycentric_coordinate_system). Wikipedia.

[^11]: Shirley, P. Marschner, S. Fundamentals of Computer Graphics, Fourth Edition. CRC Press. 2016.

[^12]: OpenGL 4.6 Reference Pages. [*OpenGL 4.6 Reference Pages*](https://registry.khronos.org/OpenGL-Refpages/gl4/).
