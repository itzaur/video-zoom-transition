import './style.scss';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
import * as dat from 'lil-gui';
import gsap from 'gsap';
import vertexShader from './shaders/vertexShader.glsl';
import fragmentShader from './shaders/fragmentShader.glsl';
import texture from '/cover.jpg';

export default class Experience {
  constructor(container) {
    this.container = document.querySelector(container);

    // Sizes
    this.width = window.innerWidth;
    this.height = window.innerHeight;

    // Parameters
    this.settings = {
      progress: 0,
      scale: 0.5,
    };

    this.videoDOM = document.querySelector('#video-bg');
    // this.videoDOM2 = document.querySelector('#video-bg2');

    this.gui = new dat.GUI();

    this.resize = () => this.onResize();
    this.mouseEventDown = () => this.onMouseEventDown();
    this.mouseEventUp = () => this.onMouseEventUp();
  }

  init() {
    this.createScene();
    this.createCamera();
    this.createRenderer();
    this.loadTextures();
    this.createControls();
    this.createMesh();
    this.createClock();
    this.addGUI();

    this.addListeners();

    this.renderer.setAnimationLoop(() => {
      this.render();
      this.update();
    });
  }

  createScene() {
    this.scene = new THREE.Scene();
  }

  createCamera() {
    this.camera = new THREE.OrthographicCamera(-0.5, 0.5, 0.5, -0.5, -10, 10);
    this.camera.position.z = 2;
  }

  createRenderer() {
    this.renderer = new THREE.WebGLRenderer({ antialias: true });
    this.container.appendChild(this.renderer.domElement);

    this.renderer.setSize(this.width, this.height);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

    this.renderer.setClearColor(0x000000);
  }

  loadTextures() {
    this.video = new THREE.VideoTexture(this.videoDOM);
    this.video.needUpdate = true;
    this.texture = new THREE.TextureLoader().load(texture);
    // this.videoNext = new THREE.VideoTexture(this.videoDOM2);
    // this.videoNext.needUpdate = true;
  }

  createControls() {
    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
  }

  createMesh() {
    this.geometry = new THREE.PlaneGeometry(1, 1, 1, 1);
    this.material = new THREE.ShaderMaterial({
      vertexShader,
      fragmentShader,
      // wireframe: true,
      uniforms: {
        uVideo: { value: this.video },
        uImage: { value: this.texture },
        uViewport: { value: new THREE.Vector2(this.width, this.height) },
        uCircleScale: { value: 0.5 },
        uTime: { value: 0 },
      },
    });
    this.mesh = new THREE.Mesh(this.geometry, this.material);
    this.scene.add(this.mesh);
  }

  createClock() {
    this.clock = new THREE.Clock();
  }

  render() {
    this.renderer.render(this.scene, this.camera);
    this.elapsedTime = this.clock.getElapsedTime();

    this.material.uniforms.uTime.value = this.elapsedTime;
    this.material.uniforms.uCircleScale.value = this.settings.scale;
  }

  update() {
    this.controls.update();
  }

  addListeners() {
    window.addEventListener('resize', this.resize, { passive: true });
    window.addEventListener('mousedown', this.mouseEventDown, {
      passive: true,
    });
    window.addEventListener('mouseup', this.mouseEventUp, { passive: true });
  }

  onResize() {
    this.width = window.innerWidth;
    this.height = window.innerHeight;

    this.camera.updateProjectionMatrix();

    this.renderer.setSize(this.width, this.height);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  }

  onMouseEventDown() {
    gsap.to(this.settings, {
      scale: 2,
      duration: 0.5,
    });
  }

  onMouseEventUp() {
    gsap.to(this.settings, {
      scale: 0,
      duration: 0.5,
    });
  }

  addGUI() {
    this.gui.add(this.settings, 'scale').min(0).max(2).step(0.01);
  }
}

const experience = new Experience('#app').init();
