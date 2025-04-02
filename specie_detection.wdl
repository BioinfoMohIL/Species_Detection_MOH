version 1.0


workflow Kraken2_Wf {
    input {
        File read1 
        File read2
        File db  
        String sample_id 

    }

    call Kraken2_PE {
        input:
            read1 = read1,
            read2 = read2,
            db    = db,
            sample_id = sample_id
            
    }

    output {
        File report = Kraken2_PE.report
        String specie_detected = Kraken2_PE.specie_detected
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
    String docker = "quay.io/staphb/kraken2:2.1.3"
    Int cpu = 10
  
  }
  command <<<
        mkdir db
        tar -C ./db -xzvf ~{db}  

        # determine if paired-end or not
        if ! [ -z ~{read2} ]; then
            echo "Reads are paired..."
            mode="--paired"
        fi

        # determine if reads are compressed
        if [[ ~{read1} == *.gz ]]; then
            echo "Reads are compressed..."
            compressed="--gzip-compressed"
        fi

        # Run Kraken2
        echo "Running Kraken2..."
        kraken2 $mode $compressed --threads ~{cpu} --use-names --db ./db \
        --report ~{sample_id}.report \
        --paired ~{read1} ~{read1} \
        --output -  

        awk -F'\t' '$4 == "S" {gsub(/^[ \t]+/, "", $6); print $6; exit}' ~{sample_id}.report > sd.txt

    >>>

    output {
        File report = "~{sample_id}.report"
        String specie_detected = read_string("specie_detected_name.txt")
    }

    runtime {
        docker: docker
        cpu: cpu
    }
}


 
  
 
