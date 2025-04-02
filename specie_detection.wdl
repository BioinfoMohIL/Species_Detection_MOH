version 1.0


workflow Specie_Detection {
    input {
        File read1 
        File read2
        File db  
        String sample_id 

    }

    call Detect_Specie {
        input:
            read1 = read1,
            read2 = read2,
            db    = db,
            sample_id = sample_id
            
    }

    output {
        File report = Detect_Specie.report
        String specie_detected = Detect_Specie.specie_detected
    }

    meta {
        author: "David Maimoun"
        description: "Classify paired-end reads using Kraken2"
    }
}

task Kraken2_PE {
  input {
    File db
    File read1
    File read2
    String sample_id
    String docker = "bioinfomoh/specie_detection:1"
    Int cpu = 10
  
  }
  command <<<
        ./specie_detection--read1 ~{read1} --read2 ~{read2} --cpu ~{cpu} --output_report ~{sample_id}.report --specie_detected specie_detected.txt
    >>>

    output {
        File report = "~{sample_id}.report"
        String specie_detected = read_string("specie_detected.txt")
    }

    runtime {
        docker: docker
        cpu: cpu
    }
}


 
  
 
