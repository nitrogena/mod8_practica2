//
//  CapturadoViewController.swift
//  BountyHunter
//
//  Created by Invitado on 28/10/16.
//  Copyright © 2016 Infraestructura. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

import Social

class CapturadoViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate, UIAlertViewDelegate {

    
    
    @IBOutlet weak var imgVwFoto: UIImageView!
    @IBOutlet weak var lblLongitud: UILabel!
    @IBOutlet weak var lblLatitud: UILabel!
    @IBOutlet weak var lblRecompensa: UILabel!
    @IBOutlet weak var lblDelito: UILabel!
    @IBOutlet weak var lblNombre: UILabel!
    
    
    @IBOutlet weak var btnFoto: UIButton!
    
    @IBOutlet weak var btnGuardar: UIButton!
    var fugitiveInfo: Fugitive?
    
    //declaramos property
    //PRENDER Y APAGAR PARA QUE NO CONSUMA BATERIA
    var localizador:CLLocationManager?
    
    
    @IBAction func btnGuardarTouch(sender: AnyObject) {
        let imageData = NSData(data: UIImageJPEGRepresentation(self.imgVwFoto!.image!, 1.0)!)
        self.fugitiveInfo!.image = imageData
        self.fugitiveInfo!.captdate = NSDate().timeIntervalSinceReferenceDate
        //representan numero de dias que han pasado desde una referencia como en excel
        self.fugitiveInfo!.captured = true
        
        do{
            //guardamos en base de datos
            try DBManager.instance.managedObjectContext?.save()
            
            //enviamos correo
            let googleMapsURL = "https://www.google.com.mx/maps/@\(self.fugitiveInfo!.capturedLat),\(self.fugitiveInfo!.capturedLon)"
            
            
            let texto = "Ya capture a \(self.fugitiveInfo!.name!) en \(googleMapsURL)"
            let laFoto = UIImage(data: self.fugitiveInfo!.image!)
            
            //si quieren enviar imagen generica
            let image = UIImage(named: "fugitivo")
            
            let hayFeiz = SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook)
            let hayTuit = SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter)
            //si existen las dos, consultar cual se usa
            if hayFeiz && hayTuit{
                
                
                if #available(iOS 8.0, *) {

                    let ac = UIAlertController(title: "Compartir", message: "compartir la captura a ", preferredStyle: .Alert)
               
                    let btnFeiz = UIAlertAction(title: "Facebook", style: .Default, handler: {
                        (UIAlertAction) in
                        let feizbuc = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
                        feizbuc.setInitialText(texto)
                        feizbuc.addImage(laFoto!)
                        self.presentViewController(feizbuc, animated: true, completion: {
                            self.navigationController?.popViewControllerAnimated(true)
                        })
                    })
                
                    let btnTuit = UIAlertAction(title: "Twitter", style: .Default, handler: {
                        (UIAlertAction) in
                        let tuiter = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
                        tuiter.setInitialText(texto)
                        tuiter.addImage(laFoto!)
                        self.presentViewController(tuiter, animated: true, completion: {
                            self.navigationController!.popViewControllerAnimated(true)
                        })
                    })
                    let noquiero = UIAlertAction(title: "No gracias", style: .Destructive, handler: nil)
                    ac.addAction(btnFeiz)
                    ac.addAction(btnTuit)
                    ac.addAction(noquiero)
                    self.presentViewController(ac, animated: true, completion: nil)
                }
                else{
                    UIAlertView(title: "Compartir", message: "compartir la captura a ", delegate: nil, cancelButtonTitle: "Aceptar").show()
                }
            }
            
            
            //VAMOS A USAR EL FRAMEWORK SOCIAL 29-10-16
                //este codigo se uso arriba
            /*
            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
                let feizbuc = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
                feizbuc.setInitialText(texto)
                feizbuc.addImage(laFoto!)
                self.presentViewController(feizbuc, animated: true, completion: {
                    self.navigationController?.popViewControllerAnimated(true)
                })
            }
            else if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter)
            {
                let tuiter = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
                tuiter.setInitialText(texto)
                tuiter.addImage(laFoto!)
                self.presentViewController(tuiter, animated: true, completion: {
                    self.navigationController!.popViewControllerAnimated(true)
                })
            } */
            else{
            
                //whatsapp no pueden compartir dos elementos al mismo tiempo
                //let items:Array<AnyObject> = [laFoto!]
            
            
            
                //decidimos si queremos enviar laFoto o la image (que es un icono que maneja el ide)
                let items:Array<AnyObject> = [image!, texto, laFoto!]
                let avc = UIActivityViewController(activityItems: items, applicationActivities: nil)
                //esto es necesario solo para el correo
                avc.setValue("¡Fugitivo Capturado!", forKey: "Subject")
                
                if UIDevice.currentDevice().userInterfaceIdiom == .Phone{
                    self.presentViewController(avc, animated: true, completion: {
                        //para que regrese a la pantalla de la que
                        self.navigationController?.popViewControllerAnimated(true)
                        
                        
                    })
                
                }else{
                    let popover = UIPopoverController(contentViewController: avc)
                    popover.presentPopoverFromRect(self.btnGuardar.frame, inView: self.view, permittedArrowDirections: .Any, animated: true)
                }
            }
        
        
        }
        catch{
            print("Error al salvar la BD")
        }
    }
    
    @IBAction func btnFotoTouch(sender: AnyObject) {
        
        
        let imagePickerController: UIImagePickerController = UIImagePickerController()
        imagePickerController.modalPresentationStyle = .FullScreen
        // =.CurrentContext
        
        //para la galeria con .photolibrary
        //imagePickerController.sourceType = .PhotoLibrary
        
        //para la camara
        imagePickerController.sourceType = .Camera
        
        imagePickerController.delegate = self
        //permiso para editar
        imagePickerController.allowsEditing = true
        //este es como el allert controller
        self.presentViewController(
            imagePickerController, animated:true,
            completion:nil)

        
    }
    
    //se cierra el picker y me dice que foto tomo el usuario de la camara o galeria
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let image:UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        //esta es la imagen que el usuario recortò, solo esta disponible si el objeto
        //imagepicker se configura con la opcion allowsEditing = true
        
        //let image:UIImage = info[UIImagePickerControllerEditedImage] as! UIImage
        
        //ESTO ES DEL EJEMPLO DE EJERCICIO ANTERIOR  PERO PARA ESTE
        //CASO NO SE NECESITIA CREAR
        /*
        let selectedFoto:UIImageView = UIImageView(image: image)
        selectedFoto.frame = CGRectMake(16, 100, 288, 192);
        
        selectedFoto.frame = CGRectMake(16, 100, 120, 80);
        
        //lo coloco en la vista
        self.view.addSubview(selectedFoto)
        */
        
        self.imgVwFoto.image = image
        
        self.dismissViewControllerAnimated(true, completion:nil)
    }
    
    //hace clic en el cancel
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion:nil)
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //precision deseada
        self.localizador = CLLocationManager()
        self.localizador?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        //poner el protocolo CLLocationManagerDelegate
        self.localizador?.delegate = self
        
        /* para el xcode 8.?
         let autorizado = CLLocationManager.authorizationStatus()
         if autorizado == CLAuthorizationStatus.NotDetermined{
         self.localizador?.requestWhenInUseAuthorization()
         }
         //requiere llave en info.plist que es la de NSLocationWhenUseUsageDescription
         */
        
        
        //lanza el
        self.localizador?.startUpdatingLocation()
        
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.lblNombre!.text = self.fugitiveInfo?.name
        self.lblDelito!.text = self.fugitiveInfo?.desc
        
        //self.lblRecompensa!.text = self.fugitiveInfo?.bounty as! String
        
        self.lblRecompensa.text = "\(fugitiveInfo?.bounty)"
        
        
        /*se va a poner con gps*/
        //self.lblLatitud!.text = self.fugitiveInfo?.capturedLat as! String
        //self.lblLatitud!.text = "\(fugitiveInfo?.capturedLat)"
        
        
        //self.lblLongitud!.text = self.fugitiveInfo?.capturedLon as! String
        //self.lblLongitud!.text = "\(fugitiveInfo?.capturedLon)"
        
        
        //self.imgVwFoto!.image = UIImage(data: self.fugitiveInfo.image)
        

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError){
        self.localizador?.stopUpdatingLocation()
        
        if #available(iOS 8.0, *) {
            let ac = UIAlertController(title: "Error", message: "no se pueden obtener lecturas de gsp",     preferredStyle: .Alert)
            let ab = UIAlertAction(title: "so sad...", style: .Default, handler: nil)
            ac.addAction(ab)
            
            self.presentViewController(ac, animated: true, completion: nil)
        }
        else{
            UIAlertView(title: "Mensaje", message: "no se pueden obtener lecturas de gsp", delegate: nil, cancelButtonTitle: "Aceptar").show()
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let ubicacion = locations.last
        self.lblLatitud.text = "\(ubicacion!.coordinate.latitude)"
        self.lblLongitud.text = "\(ubicacion!.coordinate.longitude)"
        
        
        //PARA GUARDAR LA INFORMACION CON BOTON GUARDAR
        self.fugitiveInfo?.capturedLat = ubicacion!.coordinate.latitude
        self.fugitiveInfo?.capturedLon = ubicacion!.coordinate.longitude
        
        
        //TODO: Determinar si se dejan tomar lecturas
        
        //6
        //self.colocarMapa(ubicacion!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let av = UIAlertView(title: "Compartir", message: "Compartir esta captura a...", delegate: self, cancelButtonTitle: "Facebook", otherButtonTitles: "Twitter", "No gracias")
        av.show()
    }
    
    //Esta funcion es por que se usa el delegate arriba
    func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex == 0 {  // Es el primer boton de izquierda a derecha
            print ("Compartir a Facebook")
        }
        else {
            print ("Compartir a Twitter")
        }
    }



}
