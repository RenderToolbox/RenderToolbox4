# Import the Blender-Python API module
import bpy

# Import other useful modules
import mathutils
import math
import random
import sys

# Helper Method to rotate an object so that it points at a target
def pointObjectToTarget(obj, targetLoc):
    dx = targetLoc.x - obj.location.x;
    dy = targetLoc.y - obj.location.y;
    dz = targetLoc.z - obj.location.z;
    xRad = math.atan2(dz, math.sqrt(dy**2 + dx**2)) + math.pi/2;
    zRad = math.atan2(dy, dx) - math.pi/2;
    obj.rotation_euler = mathutils.Euler((xRad, 0, zRad), 'XYZ');

# Helper method to create a random surface (resembling spilled liquid)  
# by blitting Gaussians and truncating the result  
def createRandomSurfaceMap(xBinsNum, yBinsNum):
    sigmaX = 1/3.2;
    sigmaY = 1/3.2;
    elevationMap = [[0 for x in range(0,xBinsNum)] for y in range(0,yBinsNum)];
    for y in range (0, yBinsNum ):
        for x in range(0,xBinsNum):
            xc = 2*(x-xBinsNum/2+0.5)/xBinsNum;
            yc = 2*(y-yBinsNum/2+0.5)/yBinsNum;
            z  = random.random()*math.pow(math.exp(-0.5*(math.pow(xc/sigmaX,2)+math.pow(yc/sigmaY,2))),0.7);
            if z > 0.25:
               z = 0.25;
            elevationMap[y][x] = z;
    return(elevationMap);


# Helper method to create an elevation map (resembling a stretched cloth) 
# by blitting elongated Gaussians at random positions/orientations
def createRandomGaussianBlobsMap(xBinsNum, yBinsNum):
    # create a 2D list and fill it with 0
    elevation = [[0 for x in range(0,xBinsNum)] for y in range(0,yBinsNum)];
     
    # allocate memory
    fx = [0 for x in range(0, xBinsNum)];
    fy = [0 for y in range(0, yBinsNum)];
    fySinTheta = [0 for y in range(0, yBinsNum)];
    fyCosTheta = [0 for y in range(0, yBinsNum)];
     
    peakPos         = mathutils.Vector((0.0, 0.0));
    positionSigma   = mathutils.Vector((1/3.0,  1/3.0));
    dx              = 1.0/xBinsNum;
    dy              = 1.0/yBinsNum;
  
    # medium + small elongated bumps
    mediumBumpsNum = 200;
    smallBumpsNum  = 100;
    for bumpIndex in range(1,mediumBumpsNum+smallBumpsNum):
        # give some feedback regarding the progress
        print('Generating gaussian blob #{} of {}'.format(bumpIndex, mediumBumpsNum+smallBumpsNum));
        sys.stdout.flush()
        
        # randomize Gaussian sigmas
        bumpSigmaX = (0.16+random.random())*0.03;
        if bumpIndex > mediumBumpsNum:
           bumpSigmaX = (0.12+random.random())*0.03;
        bumpSigmaY = (6.0 + 2*random.random())*bumpSigmaX;

        # randomize Gaussian position around main radius
        randomRadius = random.gauss(0.9, 0.35);  
        if (randomRadius < 0.0):
            continue;  
        randomTheta  = random.random()*2.0*math.pi + 2.0*math.pi;
        randomXpos   = randomRadius * math.cos(randomTheta);
        randomYpos   = randomRadius * math.sin(randomTheta);
        xc = peakPos.x + randomXpos;
        yc = peakPos.y + randomYpos;

        # this choice of Gaussian orientation results in an elevation map resembling a stretched cloth
        gaussianOrientaton = randomTheta - math.pi/2.0 + random.gauss(0, math.pi/60);
        sinTheta = math.sin(gaussianOrientaton);
        cosTheta = math.cos(gaussianOrientaton);
        
        # precompute some stuff
        for y in range(0, yBinsNum):
            fy[y] = 2*(y-yBinsNum/2+0.5)/yBinsNum - yc;
            fySinTheta[y] = fy[y] * sinTheta;
            fyCosTheta[y] = fy[y] * cosTheta;

        # blit the Gaussian
        for x in range(0, xBinsNum):
            fx[x] = 2*(x-xBinsNum/2+0.5)/xBinsNum - xc;
            fxCosTheta = fx[x] * cosTheta;
            fxSinTheta = fx[x] * sinTheta;
            for y in range(0, yBinsNum):
                xx = fxCosTheta - fySinTheta[y];
                yy = fxSinTheta + fyCosTheta[y];
                elevation[y][x] += math.exp(-0.5*(math.pow(xx/bumpSigmaX,2.0) + math.pow(yy/bumpSigmaY,2.0)));
    
    # normalize elevation to 1.0  
    maxElevation = max(max(elevation));
    minElevation = min(min(elevation));
    maxElevation = max([maxElevation, -minElevation]);
    rows = len(elevation);
    cols = len(elevation[0]);
    for y in range(0, rows):
        for x in range(0, cols):
            elevation[y][x] *= 1.0/maxElevation;

    # return computed elevation map
    return(elevation);


# Class for managing basscene components    
class sceneManager:
    # ---- Method to initialize the SceneManager object -----
    def __init__(self, params):  

        if ('erasePreviousScene' in params) and (params['erasePreviousScene'] == True):
            # Remove objects from previous scene
            self.erasePreviousContents();
            
        # Set the scene name
        if 'name' in params:
            bpy.context.scene.name = params['name'];
        
        # Set the unit system to Metric and the unit scale to 1.0 cm 
        bpy.context.screen.scene.unit_settings.system = 'METRIC';
        if 'sceneUnitScale' in params:
            bpy.context.screen.scene.unit_settings.scale_length = params['sceneUnitScale'];

        # set the grid spacing and the number of grid lines
        if ('sceneGridSpacing' in params) and ('sceneGridLinesNum' in params):
            self.setGrid(params['sceneGridSpacing'], params['sceneGridLinesNum']);
            # set the size of the displayed grid lines
            bpy.context.scene.tool_settings.normal_size = params['sceneGridLinesNum'];

        # Set rendering params
        # exposure boost    
        bpy.data.worlds[0].exposure = 1.0;
        # contrast boost
        bpy.data.worlds[0].color_range = 1;

        # Set rendering resolution   
        bpy.context.scene.render.resolution_x = params['sceneWidthInPixels'];
        bpy.context.scene.render.resolution_y = params['sceneHeightInPixels'];
        # Set rendering quality (highest possible)
        bpy.context.scene.render.resolution_percentage = 100;
        bpy.context.scene.render.use_antialiasing = True
        bpy.context.scene.render.use_full_sample = True

        # Set image format
        bpy.context.scene.render.image_settings.file_format = 'TIFF'
        bpy.context.scene.render.image_settings.quality     = 100;
        bpy.context.scene.render.image_settings.color_mode  = 'RGB';

        # Set BLENDER as the rendering engine
        bpy.context.scene.render.engine = 'BLENDER_RENDER';
        
        # Set CYCLES as the rendering engine
        #bpy.context.scene.render.engine = 'CYCLES';
        bpy.context.scene.cycles.samples = 100;
        bpy.context.scene.cycles.film_exposure = 5;

        # Generate a transparent material (used to bypass collada issue with Blender area lights)
        params = {'name'              : 'transparent material',
                  'diffuse_shader'    : 'LAMBERT',
                  'diffuse_intensity' : 1.0,
                  'diffuse_color'     : mathutils.Vector((1.0, 1.0, 1.0)),
                  'specular_shader'   : 'WARDISO',
                  'specular_intensity': 1.0,
                  'specular_color'    : mathutils.Vector((1.0, 1.0, 1.0)),
                  'alpha'             : 0.0,
        };        
        self.transparentMaterial = self.generateMaterialType(params);



    # ---- Method to erase a previous scene ----------------
    def erasePreviousContents(self):
        print('Erasing previous scene components')
        self.unlinkAllObjects();
        self.removeAllMeshes();
        self.removeAllLamps();
        self.removeAllCameras();
        self.removeAllMaterials();
        self.removeAllObjects();
        
    # Method to remove a single oject from the current scene
    def removeObjectFromScene(self,  object):
        # Remove the object from the scene
        print('Removing object "{}", from old scene ("{}")'.format(object.name, bpy.context.scene.name));
        bpy.data.objects.remove(object);
        
    # Method to remove all objects from the current scene
    def removeAllObjects(self):
        for object in bpy.data.objects:
            self.removeObjectFromScene(object);  
         
    def unlinkObjectFromScene(self,  object):
        # Check to see if the object is in the scene, and if it is, unlink it from the scene
        if object.name in bpy.context.scene.objects:
            bpy.context.scene.objects.unlink(object);
            print('Unlinking object "{}", from old scene ("{}")'.format(object.name, bpy.context.scene.name));
               
    # Method to unlink all objects from the current scene
    def unlinkAllObjects(self):
        for object in bpy.data.objects:
            # we can unlink an object only when in OBJECT mode
            if bpy.ops.object.mode_set.poll(): 
                bpy.ops.object.mode_set(mode='OBJECT') 
            self.unlinkObjectFromScene(object);
            
    # Method to remove all mesh data
    def removeAllMeshes(self):
        for mesh in bpy.data.meshes:
            print('Clearing all users for mesh "{}"'.format(mesh.name));
            mesh.user_clear();
            print('Removing mesh "{}", from old scene ("{}")'.format(mesh.name, bpy.context.scene.name));
            bpy.data.meshes.remove(mesh);
            
    # Method to remove all lamp data
    def removeAllLamps(self):
        for lamp in bpy.data.lamps:
            print('Clearing all users for lamp "{}"'.format(lamp.name));
            lamp.user_clear();
            print('Removing lamp "{}", from old scene ("{}")'.format(lamp.name, bpy.context.scene.name));
            bpy.data.lamps.remove(lamp);
            
    # Method to remove all camera data
    def removeAllCameras(self):
        for camera in bpy.data.cameras:
            print('Clearing all users for camera "{}"'.format(camera.name));
            camera.user_clear();
            print('Removing camera "{}", from old scene ("{}")'.format(camera.name, bpy.context.scene.name));
            bpy.data.cameras.remove(camera);
            
    # Method to remove all material data
    def removeAllMaterials(self):
        for material in bpy.data.materials:
            print('Clearing all users for material "{}"'.format(material.name));
            material.user_clear();
            print('Removing material "{}", from old scene ("{}")'.format(material.name, bpy.context.scene.name));
            bpy.data.materials.remove(material);
            
    # ---- Method to set the grid spacing and the number of grid lines ----     
    def setGrid(self, gridSpacing, gridLinesNum):
        # Search all Blender windows to find the grid_space parameter
        # print('Will search {} Blender windows'.format(len(bpy.data.screens)));
        foundGridParam = False;
        for screen in bpy.data.screens:
            # print('  Screen {} has {} areas'.format(screen.name, len(screen.areas)));
            # Loop through all areas to find one who's type is 'VIEW_3D'
            # Such an area is a subclass of SpaceView3D, in which grid params are defined
            for area in screen.areas:
                # print('   Area is of type {}'.format(area.type));
                if area.type == 'VIEW_3D':
                    # search through the spaces to find spaces with type VIEW_3D
                    # print('    Will search {} spaces in current area'.format(len(area.spaces)))
                    for space in area.spaces:
                        if space.type == 'VIEW_3D':
                            #print('    >> Setting grid scale')
                            foundGridParam = True;
                            space.grid_scale = gridSpacing;
                            space.grid_lines = gridLinesNum;
        if not(foundGridParam):
            print('Did not find any "VIEW_3D" space in which the grid is defined');

    # Method to generate a camera type
    def generateCameraType(self, params):
        # generate a camera type
        theCameraType = bpy.data.cameras.new('CAMERA');
        # configure the camera type
        theCameraType.type        = 'PERSP' ;               # perspective camera
        theCameraType.angle_x     =  params['fieldOfViewInDegrees']/180*math.pi;
        if 'widthToHeightAspectRatio' in params:
        	print('before camera sensor: {} x {}; image resolution: {} x {}; horiz FOV = {}'.format(theCameraType.sensor_width, theCameraType.sensor_height, bpy.data.scenes[0].render.resolution_x, bpy.data.scenes[0].render.resolution_y, theCameraType.angle_x));
        	aspectRatio = theCameraType.sensor_width / theCameraType.sensor_height;
        	theCameraType.sensor_height = theCameraType.sensor_width / params['widthToHeightAspectRatio'];
        	bpy.data.scenes[0].render.resolution_x = params['pixelSamplesAlongWidth'];
        	bpy.data.scenes[0].render.resolution_y = bpy.data.scenes[0].render.resolution_x / params['widthToHeightAspectRatio'];
        	print('after camera sensor: {} x {}; image resolution: {} x {}; horiz FOV = {}'.format(theCameraType.sensor_width, theCameraType.sensor_height, bpy.data.scenes[0].render.resolution_x, bpy.data.scenes[0].render.resolution_y, theCameraType.angle_x));

        theCameraType.clip_start  =  params['clipRange'][0];
        theCameraType.clip_end    =  params['clipRange'][1];
        theCameraType.draw_size   =  params['drawSize'];     # apparent size of Camera object in 3D View
        theCameraType.show_limits =  True;                   # draw clipping range and focus point
        return(theCameraType);
    
    # Method to add a camera object to the current scene
    def addCameraObject(self,params):
        # generate the container object
        theCameraObject = bpy.data.objects.new(params['name'], params['cameraType']);
        theCameraObject.show_name = params['showName'];
        # position the camera object
        theCameraObject.location  = params['location'];
        # rotate the camera object so that it looks at the desired position
        pointObjectToTarget(theCameraObject, params['lookAt']);
        # link the camera object to the current scene (if not linked, the camera is not functional)
        bpy.context.screen.scene.objects.link(theCameraObject);
        return(theCameraObject);
    
    # Method to generate an area lamp type     
    def generateAreaLampType(self, params):
        # generate a lamp type
        theLampType = bpy.data.lamps.new(params['name'], 'AREA');
        # configure the lamp type
        theLampType.energy          = 1;
        theLampType.color           = params['color'];      
        theLampType.use_specular    = True;
        theLampType.use_diffuse     = True;
        theLampType.distance        = params['fallOffDistance'];  # falloff distance (1/2 intensity) in cm
        theLampType.shape           = 'RECTANGLE';
        theLampType.size            = params['width1'];
        theLampType.size_y          = params['width2']
        return(theLampType);
    
    # Method to generate a directional lamp type     
    def generateDirectionalLampType(self, params):
        # generate a lamp type
        theLampType = bpy.data.lamps.new(params['name'], 'SUN');
        # configure the lamp type
        return(theLampType);


    # Method to add a lamp object to the current scene
    def addLampObject(self,params):
        # generate a lamp object
        theLampObject           = bpy.data.objects.new(params['name'], params['model']);
        theLampObject.show_name = params['showName'];
        # position the lamp object
        theLampObject.location  = params['location'];
        # rotate the lamp object so that it looks at the desired position
        pointObjectToTarget(theLampObject, params['lookAt']);
        # link the lamp object to the current scene (if not linked, the lamp is not functional)
        bpy.context.screen.scene.objects.link(theLampObject);

        # Check whether we are adding a Blender area lamp object ...
        if params['model'].type == 'AREA':
            # add a transparent planar Quad at the same xyz coords, which RT3 will transform into an area light
            quadParams = {'name'       : '{}-geomObject'.format(params['name']),
                          'scaling'    : mathutils.Vector((params['model'].size, params['model'].size_y, 1)),
                          'rotation'   : mathutils.Vector((0, 0, 0)),
                          'location'   : params['location'],
                          'material'   : self.transparentMaterial,
                          'flipNormal' : True,
                         };
            quadOBJ = self.addPlanarQuad(quadParams); 
            # rotate the lamp object so that it looks at the desired position
            pointObjectToTarget(quadOBJ, params['lookAt']);
            # rename the underlying mesh so RT3 can access it
            bpy.data.meshes[quadOBJ.data.name].name = '{}'.format(params['name']);
            print('Area light mesh name for RT3: {}'.format(bpy.data.meshes[quadOBJ.data.name].name));
            

    # Method to add a matte material
    def generateMaterialType(self, params):
        theMaterialType = bpy.data.materials.new(params['name']);
        # Options for diffuse shaders: Minnaert, Fresnel, Toon, Oren-Nayar, Lambert
        theMaterialType.diffuse_shader      = params['diffuse_shader'];
        theMaterialType.diffuse_intensity   = params['diffuse_intensity'];
        theMaterialType.diffuse_color       = params['diffuse_color'];
        # Options for specular shaders: CookTorr, Phong, Blinn, Toon, WardIso
        theMaterialType.specular_shader     = params['specular_shader'];
        theMaterialType.specular_intensity  = params['specular_intensity'];
        theMaterialType.specular_color      = params['specular_color'];
        # Transparency options
        theMaterialType.ambient             = 1;
        theMaterialType.alpha               = params['alpha'];
        theMaterialType.use_transparency    = True;
        theMaterialType.transparency_method = 'RAYTRACE';

        #theMaterialType.raytrace_mirror.depth = 5;
        #theMaterialType.raytrace_mirror.use = True;
        return(theMaterialType);  

    # Method to add a cube at a specified location, rotation with specified scaling and material
    def addCube(self, params):
        bpy.ops.mesh.primitive_cube_add();
        theCube          = bpy.context.active_object;
        theCube.name     = params['name'];
        theCube.rotation_euler = params['rotation'];
        theCube.scale    = params['scaling'];
        theCube.location = params['location'];
        # attach a material 
        theCube.data.materials.append(params['material']);
        # return the generated object
        return(theCube);

    # Method to add a cylinder with a desired scale, rotation, and location
    def addCylinder(self,params):
        # Create cylinder
        bpy.ops.mesh.primitive_cylinder_add(vertices=128, radius=1, depth=1, end_fill_type='NGON');
        theCylinder                = bpy.context.active_object;
        theCylinder.name           = params['name'];
        theCylinder.rotation_euler = params['rotation'];
        theCylinder.scale          = params['scaling'];
        theCylinder.location       = params['location'];
        # attach a material 
        theCylinder.data.materials.append(params['material']);
        # return the generated object
        return(theCylinder);

    # Method to add a sphere with a desired scale, and location
    def addSphere(self,params):
        # Create sphere
        if 'subdivisions' in params:
            subdivisionsNum = params['subdivisions'];
        else:
            subdivisionsNum = 5;
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisionsNum, size=1);
        theSphere          = bpy.context.active_object;
        theSphere.name     = params['name'];
        theSphere.scale    = params['scaling'];
        theSphere.location = params['location'];
        # attach a material 
        theSphere.data.materials.append(params['material']);
        return(theSphere);

    def addPlanarQuad(self, params):
        if 'vertices' in params:
            # Generate the mesh for the plane.
            vertices = params['vertices'];
        else:
            vertices = [(-0.5, -0.5, 0),(0.5, -0.5, 0),(0.5, 0.5, 0),(-0.5, 0.5, 0)];
        # edges: pairs, each pais containing two indices to the vertices list
        edges = [];
        # faces: list of N-tuples (N >= 3) containing indices to the vertices list
        if params['flipNormal'] == True:
            faces = [(3,2,1,0)];
        else:
            faces = [(0,1,2,3)];
        theMesh = bpy.data.meshes.new('{}-mesh'.format(params['name'])); 
        theMesh.from_pydata(vertices, edges, faces); 
        theMesh.validate();
        theMesh.update();

        # generate encapsulating plane object
        thePlanarQuad                = bpy.data.objects.new(params['name'], theMesh);
        thePlanarQuad.name           = params['name'];
        thePlanarQuad.scale          = params['scaling'];
        thePlanarQuad.rotation_euler = params['rotation'];
        thePlanarQuad.location       = params['location'];
        # attach a material 
        if 'material' in params:
            thePlanarQuad.data.materials.append(params['material']);
        # link the plane to the scene
        bpy.context.scene.objects.link(thePlanarQuad);
        #  the normal will be shown only in EditMode in the 3D View viewport
        thePlanarQuad.data.show_normal_face = True;
        return(thePlanarQuad);

    # Method to add a room. Note: if you want to make openings in the room
    # using the boreOut method, the room must have a specified 'wallThickness'.
    def addRoom(self, roomParams):
        roomLocation = roomParams['roomLocation'];
        roomWidth    = roomParams['roomWidth'];
        roomDepth    = roomParams['roomDepth'];
        roomHeight   = roomParams['roomHeight'];

        # the floor plane
        params = { 'name'       : roomParams['floorName'],
                   'scaling'    : mathutils.Vector((roomWidth, roomDepth, 0.1)),
                   'rotation'   : mathutils.Vector((0, 0, 0)),
                   'location'   : mathutils.Vector((roomLocation.x, roomLocation.y, roomLocation.z)),
                   'material'   : roomParams['floorMaterialType'],
                   'flipNormal' : False,
                 };
        if ('wallThickness' in roomParams):
            params['scaling'].x = roomWidth/2;
            params['scaling'].y = roomDepth/2;
            params['scaling'].z = roomParams['wallThickness'];
            if params['location'].z < 0:
                params['location'].z += roomParams['wallThickness'];
            else:
                params['location'].z -= roomParams['wallThickness'];
            floorPlane = self.addCube(params);
        else:
            floorPlane = self.addPlanarQuad(params);

        # the backwall
        params = { 'name'       : roomParams['backWallName'],
                   'scaling'    : mathutils.Vector((roomWidth, roomHeight, 0.1)),
                   'rotation'   : mathutils.Vector((math.pi/2, 0, 0)),
                   'location'   : mathutils.Vector((roomLocation.x, roomLocation.y+roomDepth/2, roomLocation.z+roomHeight/2)),
                   'material'   : roomParams['backWallMaterialType'],
                   'flipNormal' : False,
                 };
        if ('wallThickness' in roomParams):
            params['scaling'].x = roomWidth/2;
            params['scaling'].y = roomHeight/2;
            params['scaling'].z = roomParams['wallThickness'];
            if params['location'].y < 0:
                params['location'].y += roomParams['wallThickness'];
            else:
                params['location'].y -= roomParams['wallThickness'];
            backWallPlane = self.addCube(params);
        else:
            backWallPlane = self.addPlanarQuad(params);


        # the left wall
        params = { 'name'       : roomParams['leftWallName'],
                   'scaling'    : mathutils.Vector((roomHeight, roomDepth, 0.1)),
                   'rotation'   : mathutils.Vector((0,math.pi/2,0)),
                   'location'   : mathutils.Vector((roomLocation.x-roomWidth/2, roomLocation.y, roomLocation.z+roomHeight/2)),
                   'material'   : roomParams['leftWallMaterialType'],
                   'flipNormal' : False,
                 };
        if ('wallThickness' in roomParams):
            params['scaling'].x = roomHeight/2;
            params['scaling'].y = roomDepth/2;
            params['scaling'].z = roomParams['wallThickness'];
            if params['location'].x < 0:
                params['location'].x += roomParams['wallThickness'];
            else:
                params['location'].x -= roomParams['wallThickness'];
            leftWallPlane = self.addCube(params);
        else:
            leftWallPlane = self.addPlanarQuad(params);

        # the right wall
        params = { 'name'       : roomParams['rightWallName'],
                   'scaling'    : mathutils.Vector((roomHeight, roomDepth, 0.1)),
                   'rotation'   : mathutils.Vector((0,-math.pi/2,0)),
                   'location'   : mathutils.Vector((roomLocation.x+roomWidth/2, roomLocation.y, roomLocation.z+roomHeight/2)),
                   'material'   : roomParams['rightWallMaterialType'],
                   'flipNormal' : False,
                 };
        if ('wallThickness' in roomParams):
            params['scaling'].x = roomHeight/2;
            params['scaling'].y = roomDepth/2;
            params['scaling'].z = roomParams['wallThickness'];
            if params['location'].x < 0:
                params['location'].x += roomParams['wallThickness'];
            else:
                params['location'].x -= roomParams['wallThickness'];
            rightWallPlane = self.addCube(params);
        else:
            rightWallPlane = self.addPlanarQuad(params);

        # the frontwall
        params = { 'name'       : roomParams['frontWallName'],
                   'scaling'    : mathutils.Vector((roomWidth, roomHeight, 0.1)),
                   'rotation'   : mathutils.Vector((-math.pi/2, 0, 0)),
                   'location'   : mathutils.Vector((roomLocation.x, roomLocation.y-roomDepth/2, roomLocation.z+roomHeight/2)),
                   'material'   : roomParams['frontWallMaterialType'],
                   'flipNormal' : False,
                 };
        if ('wallThickness' in roomParams):
            params['scaling'].x = roomWidth/2;
            params['scaling'].y = roomHeight/2;
            params['scaling'].z = roomParams['wallThickness'];
            if params['location'].y < 0:
                params['location'].y += roomParams['wallThickness'];
            else:
                params['location'].y -= roomParams['wallThickness'];
            frontWallPlane = self.addCube(params);
        else:
            frontWallPlane = self.addPlanarQuad(params);


        # the ceiling plane
        params = { 'name'       : roomParams['ceilingName'],
                   'scaling'    : mathutils.Vector((roomWidth, roomDepth, 0.1)),
                   'rotation'   : mathutils.Vector((math.pi, 0, 0)),
                   'location'   : mathutils.Vector((roomLocation.x, roomLocation.y, roomLocation.z+roomHeight)),
                   'material'   : roomParams['ceilingMaterialType'],
                   'flipNormal' : False,
                 };
        if ('wallThickness' in roomParams):
            params['scaling'].x = roomWidth/2;
            params['scaling'].y = roomDepth/2;
            params['scaling'].z = roomParams['wallThickness'];
            if params['location'].z < 0:
                params['location'].z += roomParams['wallThickness'];
            else:
                params['location'].z -= roomParams['wallThickness'];
            ceilingPlane = self.addCube(params);
        else:
            ceilingPlane = self.addPlanarQuad(params);


        # Generate a dictionary with the room's surface planes return the room surfaces
        surfacesDict = {
                    'floorPlane'        : floorPlane,
                    'backWallPlane'     : backWallPlane,
                    'leftWallPlane'     : leftWallPlane,
                    'rightWallPlane'    : rightWallPlane,
                    'frontWallPlane'    : frontWallPlane,
                    'ceilingPlane'      : ceilingPlane,
                    }

        # and return it
        return(surfacesDict);



    # Method to generate a mesh object from an elevation map
    def addElevationMapObject(self, params):
        # compute vertices
        vertices = [];
        numX      = params['xBinsNum'];
        numY      = params['yBinsNum'];
        elevation = params['elevationMap'];

        for y in range (0, numY):
            for x in range(0,numX):
                xc = 2*(x-(numX-1.5)/2)/(numX-2);
                yc = 2*(y-(numY-1.5)/2)/(numY-2);
                vertices.append((xc, yc, elevation[y][x]));
 
        # Fill faces array.
        # Each item in the face array contains 4 indices that refer to items in the vertices array.
        count = 0;
        faces = [];
        for i in range (0, numY*(numX-1)):
            if count < numX-1:
                A = i;              # first vertex
                B = i+1;            # second vertex
                C = (i+numX)+1;     # third vertex
                D = (i+numX);       # fourth vertex
                face = (A,B,C,D);
                faces.append(face);
                count = count + 1
            else:
                count = 0
 
        #create mesh and object
        theRandomSurfaceMesh   = bpy.data.meshes.new('{}-mesh'.format(params['name']));
        theRandomSurfaceObject = bpy.data.objects.new(params['name'], theRandomSurfaceMesh);
        # set object location and scale
        theRandomSurfaceObject.location       = params['location'];
        theRandomSurfaceObject.scale          = params['scale'];
        theRandomSurfaceObject.rotation_euler = params['rotation'];
        #create mesh from python data
        theRandomSurfaceMesh.from_pydata(vertices,[],faces)
        theRandomSurfaceMesh.update()
        # subdivide modifier
        #theRandomSurfaceObject.modifiers.new("subd", type='SUBSURF')
        #theRandomSurfaceObject.modifiers['subd'].levels = 3;
        # smooth the mesh's polygons
        for polygon in theRandomSurfaceMesh.polygons:
            polygon.use_smooth = True
        # attach a material
        theRandomSurfaceObject.data.materials.append(params['material']);
        # link it to current scene to make it visible
        bpy.context.scene.objects.link(theRandomSurfaceObject);
        # return the generated object
        return(theRandomSurfaceObject);


    # Method to subtract (boring out) one geometric object from another 
    def boreOut(self, targetObject, boringObject, hideBoringObject):
        # Deselect all object
        bpy.ops.object.select_all(action='DESELECT')
        # make the target object active and select it
        bpy.context.scene.objects.active = targetObject;
        targetObject.select = True;
        # add a modifier to the target object
        objectModifiersNum = len(bpy.context.object.modifiers);
        bpy.ops.object.modifier_add(type='BOOLEAN')
        bpy.context.object.modifiers[objectModifiersNum].object = boringObject;
        bpy.context.object.modifiers[objectModifiersNum].operation = 'DIFFERENCE'; 
        # apply modifier
        bpy.ops.object.modifier_apply(apply_as='DATA', modifier=bpy.context.object.modifiers[0].name);
        if hideBoringObject:
            # unlink the boring object from the scene so it is not visible
            self.unlinkObjectFromScene(boringObject);


    # Method to export a collada file for the current 3D scene 
    def exportToColladaFile(self, filePath):
        # Get scene 
        currentScene = bpy.data.scenes[0];
        fileName = '{}/{}.dae'.format(filePath, currentScene.name);
        #The transrotloc option is necessary for RT3 to successfully parse the collada file
        bpy.ops.wm.collada_export(filepath=fileName, export_transformation_type_selection='transrotloc');


        