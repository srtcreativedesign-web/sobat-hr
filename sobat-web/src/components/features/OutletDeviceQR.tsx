import React from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { Download, QrCode } from 'lucide-react';
import { OutletDevice } from '@/types';
import { Modal, ModalContent, ModalHeader, ModalBody, Button } from "@nextui-org/react";

interface Props {
  device: OutletDevice;
  onClose: () => void;
}

export default function OutletDeviceQR({ device, onClose }: Props) {
  const qrData = device.activation_token || '';

  const handleDownload = () => {
    const svg = document.getElementById('activation-qr');
    if (!svg) return;
    
    // Convert SVG to Canvas to download as PNG
    const svgData = new XMLSerializer().serializeToString(svg);
    const canvas = document.createElement("canvas");
    const ctx = canvas.getContext("2d");
    const img = new Image();
    img.onload = () => {
      canvas.width = img.width + 40; // Add padding
      canvas.height = img.height + 40;
      
      if(ctx) {
          // Draw background
          ctx.fillStyle = "white";
          ctx.fillRect(0, 0, canvas.width, canvas.height);
          ctx.drawImage(img, 20, 20);
          
          const pngFile = canvas.toDataURL("image/png");
          const downloadLink = document.createElement("a");
          downloadLink.download = `QR-Activation-${device.device_name}.png`;
          downloadLink.href = `${pngFile}`;
          downloadLink.click();
      }
    };
    img.src = "data:image/svg+xml;base64," + btoa(svgData);
  };

  return (
    <Modal 
        isOpen={true} 
        onClose={onClose}
        placement="center"
        classNames={{
            base: "rounded-[2.5rem] bg-white",
            header: "border-b border-slate-50 px-8 py-6",
            body: "p-8",
        }}
    >
        <ModalContent>
            {(onClose) => (
                <>
                    <ModalHeader className="flex flex-col gap-1 items-center pb-2">
                        <div className="p-3 bg-indigo-50 text-indigo-600 rounded-2xl mb-2">
                            <QrCode className="w-6 h-6" />
                        </div>
                        <h3 className="text-2xl font-black text-slate-800 tracking-tight">Master QR</h3>
                    </ModalHeader>
                    
                    <ModalBody className="flex flex-col items-center">
                        <p className="text-sm text-slate-500 text-center font-medium max-w-[280px]">
                            Scan menggunakan <span className="font-bold text-slate-800">Sobat Outlet</span> untuk menghubungkan perangkat <span className="text-indigo-600 font-bold">{device.device_name}</span>.
                        </p>

                        <div className="bg-white p-5 rounded-[2rem] shadow-[0_8px_30px_rgb(0,0,0,0.08)] my-4 relative group border border-slate-100">
                            <QRCodeSVG 
                                id="activation-qr"
                                value={qrData} 
                                size={200} 
                                level="Q"
                                includeMargin={false}
                            />
                            
                            <div className="absolute inset-0 bg-white/80 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center rounded-[2rem] backdrop-blur-[2px]">
                                <Button 
                                    onPress={handleDownload}
                                    color="primary"
                                    variant="shadow"
                                    className="font-black uppercase tracking-wider text-[10px]"
                                    startContent={<Download className="w-4 h-4" />}
                                >
                                    Download
                                </Button>
                            </div>
                        </div>
                        
                        <div className="text-center w-full bg-amber-50 text-amber-700 text-[11px] font-bold py-3 px-4 rounded-xl border border-amber-100/50 mt-2">
                            Hanya berlaku untuk 1 kali pemakaian
                        </div>
                    </ModalBody>
                </>
            )}
        </ModalContent>
    </Modal>
  );
}
