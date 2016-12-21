/* ***************************************************** */
/*     COPIA UN ARCHIVO AGREGANDO AL NOMBRE              */
/*       DD + MM + AAAA + HORA + MIN + SEG               */
/*        Y NO CANCELA SI NO LO ENCUENTRA                */
/* FECHA: 09/03/2015                                     */
/* AUTOR: ARO                                            */
/* ULTIMA MODIFICACION:                                  */
/* ***************************************************** */
parse upper arg !ambiente !nombre_proceso !pasonro !archivo_ini !PathClave !campo 
!fecha=Date('N') 
!hora=TIME('N') 
!seg=right(!hora,2)
!min=left((right(!hora,5)),2)
!hora=left(!hora,2) 
!hoy=Date('S')
!dd=right(!hoy,2)
!mm1=right(!hoy,4)
!mm=left(!mm1,2)
!yyyy=left(!hoy,4)

signal on syntax

call 0010_Nombre_Archivo_Activo		
call 0020_Logging_Open

!field=word(!campo,1)
call 0040_Leo_Registry			/* busca dentro del proceso los campos seteados con $SetVar */
!arch_ori=!dato

!arch=!arch_ori

call 0050_Check_Existencia
if rc\=0 then do
	!log_linea='Error Nro. 3505 : Archivo de Usuario no encontrado '||!arch_ori
	call 0022_Logging_Write
	call 0030_Logging_Copy
	exit 0
end
else do
	!field=word(!campo,2)
	call 0040_Leo_Registry
	
	!pos=!dato~lastpos('.')
	!len=!dato~LENGTH
	!resto=!len-(abs(!pos))
	!path_arch_dest=!dato~left(abs(!pos)-1)
	!ext=!dato~right(abs(!resto)+1)
	
	!log_linea='patharchdest'||!path_arch_dest
	call 0022_Logging_Write
	
	!log_linea='ext'||!ext
	call 0022_Logging_Write
	
	!arch_dest=!path_arch_dest||!yyyy||!mm||!dd||!hora||!min||!seg||!ext	
	
	'copy' !arch_ori !arch_dest

	if rc\=0 then do
		!log_linea='Error Nro. 3524 : No se puede hacer el copy. Archivo Origen en uso o falta de espacio.'
		call 0022_Logging_Write
		call 0030_Logging_Copy
		exit 0
	end
end

!log_file~close

exit 0


/* ********** RUTINAS ************** */
/* ********************************* */
0010_Nombre_Archivo_Activo:
parse upper source !sist_op !ambiente !arch_actual	
!drive=FILESPEC("drive", !arch_actual)
!arch=FILESPEC("name", !arch_actual)
!cant=0
!cant=!arch~LENGTH
!nombre_funcion=left(!arch,!cant-4)
return


0020_Logging_Open:
!log_file_func=!drive||'\Batch\ArchLog\'||!nombre_proceso||'\msgfun.tmp'
!log_file=.stream~new(!log_file_func)
!log_file~open 
!log_linea='------------------------------------------------'
call 0022_Logging_Write
!log_linea='* FUNCION COPYC *'
call 0022_Logging_Write
!log_linea=!fecha||' a las '||!hora
call 0022_Logging_Write
return

0022_Logging_Write:
!log_file~LINEOUT(!log_linea)
return

0030_Logging_Copy:
!log_copy=!drive||'\Batch\ArchLog\'||!nombre_proceso||'\msgcopy.tmp'
!log_out=.stream~new(!log_copy)
if !log_out~query('exists')='' then do
	!log_out~open(write)          /* no existe */
end 
else do
	!log_out~open(write append)   /* existe */
end
!log_line='Archivo de Usuario no encontrado '||!arch_ori
!log_out~LINEOUT(!log_line)
!log_out~close
return

0040_Leo_Registry:
!log_linea='0040_Leo_Registry'
call 0022_Logging_Write
r = .WindowsRegistry~new            
if r~InitCode \= 0 then exit 1	    
/* open the HKEY_LOCAL_MACHINE\SOFTWARE key. */
!arbol='SOFTWARE\BATCH\'||!nombre_proceso
if r~open(r~Local_Machine,!arbol) \= 0 then do
  myval.=r~GETVALUE(,!field)
  !dato=myval.data   
  !log_linea='Archivo: '||!dato
  call 0022_Logging_Write  
end 

return


0050_Check_Existencia:
qfile=.stream~new(!arch)
if qfile~query('exists')='' then do
	rc=1 
end 
else do
	rc=0
end
return


syntax:							
MsgErr='Rexx Error 50'|| rc ||' in line ' ||sigl||':'||"ERRORTEXT"(rc)
say MsgErr
say "SOURCELINE"(sigl)
!nro='50'||rc
exit !nro
nop 

/* winregis.rex contains the required directives for the WindowsRegistry object */
::requires "winsystm.cls"